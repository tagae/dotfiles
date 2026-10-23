#!/bin/sh
# shellcheck disable=SC3043  # `local` is not POSIX, but dash, bash and ash all have it

# Claude Code status line, compact edition: icons for the labels, no dividers, and the model by
# its initial.
#   "O5.5xh ↑87K/200K (+478, ◕42m, miss: 202K ttl_expired_5m) ↓340 $0.12 ⊂ $1.23 ⚙4m/12m ⧖ 37%↑ ↻2h10 ▦ 48%↗ ↻4d3h"
#
#   - ↑ and ↓ are the input and output tokens; ⚙ is the time on the API, then the session's time
#     after a slash, which contains it; ⧖ and ▦ are the 5-hour and 7-day quotas; ↻ is the time
#     until a quota resets.
#   - The ttl is a pie that empties with the cache's lifetime, in eighths: 󰪥󰪤󰪣󰪢󰪡󰪠󰪟󰪞 down to 󰝦. They are
#     Nerd Font glyphs (Material Design circle slices), so the terminal needs one. The plain
#     Unicode pies would not do: ◐ and ◑ are not in JetBrains Mono, and come bigger from another font.
#   - The model's initial is white (colour_white). The rest of its name, the session's cost, the input tokens and the quota figures and reset times
#     are light grey (colour_light_grey) while they have no warning colour of their own.
#   - test-compact.sh covers it. README.md describes what it shows; change both in the same commit.
#
# MAINTENANCE RULE: the notes below are only what the code does not make obvious.
#
#   - Not shown: the fresh, uncached input (with caching on it is always 2 tokens) and the
#     cache read (it is the rest of the input). (+478) is the cache write, which is how much
#     the input grew with the last response; after a cache miss it is the rebuild instead.
#   - `prompt_cache.warm` is not used: it stays true past the expiry until the next response.
#   - The payload has only running totals. A turn's cost and cache miss are their growth since
#     the prompt began, so one small file per session in /tmp (or in CLAUDE_STATUSLINE_STATE_DIR) keeps the
#     prompt id, the session cost and the miss tokens at the start of the turn, the cost of the turn before, and the
#     last response's cost and quota with when they changed. It is rewritten only when
#     something in it changes.
#   - A quota figure is what this session saw at its last response; other sessions spend the
#     same quota unseen. Every response bills something, so a cost or quota that moved means
#     one landed; the quota alone would not do, as it can sit at one percent through many.
#   - The countdowns (ttl, quota resets) only tick if the status line has a refreshInterval.
#   - Colours are for dark terminals. One fade (fade_colour) colours the ttl countdown, the input
#     tokens and the 5h and 7d percentages: plain at first, then brighter, then yellow, orange
#     and red. Nothing else uses it; the miss and the pace arrows have their own colours.
#
# Conventions: POSIX sh. Names are lowercase, since uppercase is reserved for the environment
# (CLAUDE_QUOTA_STALE_SECS and CLAUDE_STATUSLINE_STATE_DIR, where the state file goes and
# the tests point away from /tmp, are the two read from it). A number with a meaning has a
# named constant; only 0, 1, 10 and 100 (a percentage, a decimal digit) stay as they are.
# Functions keep their variables `local` (not in POSIX, but dash, bash and ash all have it)
# and hand back what they compute by printing it, never through a global.
# `errexit` and `nounset` are on, so: a function ends on a command that succeeds (`return 0`,
# never a bare `return` after a test), a command that may fail on purpose is followed by
# `|| :`, and whatever the payload may leave out is set to empty before it is read.

set -o errexit -o nounset

# shorten N -> "340", "1.2K", "15K", "1K", "1.2M", "1M": one decimal, none when it would be 0.
shorten() {
  local tenths unit
  if [ "$1" -ge $((million - thousand / 2)) ]; then   # from where 999.5K rounds up to 1M
    tenths=$((($1 + million / 20) / (million / 10))); unit=M
  elif [ "$1" -ge $((10 * thousand)) ]; then
    printf '%sK' $((($1 + thousand / 2) / thousand)); return 0
  elif [ "$1" -ge "$thousand" ]; then
    tenths=$((($1 + thousand / 20) / (thousand / 10))); unit=K
  else
    printf '%s' "$1"; return 0
  fi
  if [ $((tenths % 10)) -eq 0 ]; then printf '%s%s' $((tenths / 10)) "$unit"
  else printf '%s.%s%s' $((tenths / 10)) $((tenths % 10)) "$unit"
  fi
}

# duration SECONDS -> "45s", "12m", "3h05", "2d4h"
duration() {
  if [ "$1" -ge "$sec_per_day" ]; then
    printf '%dd%dh' $(($1 / sec_per_day)) $((($1 % sec_per_day) / sec_per_hour))
  elif [ "$1" -ge "$sec_per_hour" ]; then
    printf '%dh%02d' $(($1 / sec_per_hour)) $((($1 % sec_per_hour) / sec_per_min))
  elif [ "$1" -ge "$sec_per_min" ]; then printf '%dm' $(($1 / sec_per_min))
  else printf '%ds' "$1"
  fi
}

# colour N TEXT -> TEXT in 256-colour number N, then back to the default.
colour() { printf '%s[38;5;%sm%s%s[0m' "$esc" "$1" "$2" "$esc"; }

# lighten TEXT -> TEXT in light grey, unless it is already coloured (it starts with an escape).
lighten() {
  case $1 in
    "$esc"*) printf '%s' "$1" ;;
    *) colour "$colour_light_grey" "$1" ;;
  esac
}

# pct PERCENT TEXT YELLOW ORANGE RED -> TEXT coloured by how high PERCENT is: plain below
# YELLOW, yellow from there, orange from ORANGE, red from RED. Plain too when PERCENT is empty
# (not reported yet).
pct() {
  local rounded code
  [ -n "$1" ] || { printf '%s' "$2"; return 0; }
  rounded=$(printf '%.0f' "$1")
  if [ "$rounded" -lt "$3" ]; then printf '%s' "$2"; return 0; fi
  if [ "$rounded" -lt "$4" ]; then code=$colour_yellow
  elif [ "$rounded" -lt "$5" ]; then code=$colour_orange
  else code=$colour_red
  fi
  colour "$code" "$2"
}

# fade_colour DONE -> the colour from fade_colours for DONE percent of a range run out (a lifetime,
# a window). The step grows with the cube of DONE and reaches the last one, red, at fade_red_at, so
# the figure stays plain and grey for a good while, and the yellow, orange and red steps come faster
# and faster towards the end. Nothing while the first step is not reached.
fade_colour() {
  local step
  [ "$1" -gt 0 ] || return 0
  step=$(($1 * $1 * $1 * fade_steps / (fade_red_at * fade_red_at * fade_red_at)))
  [ "$step" -le "$fade_steps" ] || step=$fade_steps
  [ "$step" -gt 0 ] || return 0
  set -- $fade_colours   # unquoted on purpose: the list splits into its colours
  shift $((step - 1))
  printf '%s' "$1"
}

# fade PERCENT TEXT -> TEXT in the fade colour for PERCENT of a range used. Plain while the fade has
# not started, and when PERCENT is empty (not reported yet).
fade() {
  local code
  [ -n "$1" ] || { printf '%s' "$2"; return 0; }
  code=$(fade_colour "$(printf '%.0f' "$1")")
  if [ -n "$code" ]; then colour "$code" "$2"; else printf '%s' "$2"; fi
}

# pie SHARE -> the icon for SHARE percent of a lifetime left: the ttl_icons fill nearest to it,
# from the empty circle to the full one.
pie() {
  local level
  level=$((($1 * (ttl_icon_count - 1) + 50) / 100))
  set -- $ttl_icons   # unquoted on purpose: the list splits into its icons
  shift "$level"
  printf '%s' "$1"
}

# duration_to_secs TEXT -> the seconds that a number and one unit name: "30s", "5m", "1h", "2d".
# Nothing for anything else, including the compound forms `duration` prints ("3h05", "2d4h");
# no leading zero, so no octal surprises, and never zero.
duration_to_secs() {
  local n
  case "$1" in [1-9]*[smhd]) ;; *) return 0 ;; esac
  n=${1%?}
  case "$n" in *[!0-9]*) return 0 ;; esac
  case "${1#"$n"}" in
    s) echo "$n" ;;
    m) echo $((n * sec_per_min)) ;;
    h) echo $((n * sec_per_hour)) ;;
    d) echo $((n * sec_per_day)) ;;
  esac
}

# usd_to_micro USD -> dollars as an integer count of millionths ("0.1214" -> 121400), so a
# turn's cost is plain shell arithmetic. Six decimals are the millionths. The leading zeros
# go: $(( )) reads them as octal.
usd_to_micro() {
  local micro
  micro=$(printf '%.6f' "$1")
  micro="${micro%[.,]*}${micro#*[.,]}"
  while [ "${micro#0}" != "$micro" ]; do micro=${micro#0}; done
  printf '%s' "${micro:-0}"
}

# micro_to_usd MICRO -> "$1.23", rounded to cents.
micro_to_usd() {
  local cents
  cents=$((($1 + micro_per_cent / 2) / micro_per_cent))
  printf '$%d.%02d' $((cents / cents_per_dollar)) $((cents % cents_per_dollar))
}

# quota LABEL USED LEFT WINDOW_SECS STALE -> " ⧖ 37%↗ ↻2h10", with its leading space.
# LABEL is just an icon: "⧖" for the 5h window, "▦" for the 7d one. The arrow follows the figure,
# where the "?" goes when stale.
# LEFT is the seconds until the quota resets (empty if unknown, zero or less once it has);
# STALE is non-empty for a figure this session has not seen move lately.
# An arrow compares the quota left with the window left:
# ↑ well ahead, ↗ ahead (both light green), none on pace, ↘ behind (yellow), ↓ far behind (red).
# A stale figure, or one whose window has ended, is grey, "37%?", and loses its arrow.
quota() {
  local used arrow pace
  [ -n "$2" ] || return 0
  used=$(printf '%.0f' "$2")
  if [ -n "$5" ] || { [ -n "$3" ] && [ "$3" -le 0 ]; }; then
    printf ' %s %s' "$1" "$(colour "$colour_grey" "${used}%?")"
  else
    # Quota left over window left, times 100: (100 - used) / 100 / (left / window) * 100.
    arrow=
    if [ "${3:-0}" -gt 0 ]; then
      pace=$(((100 - used) * $4 / $3))
      if [ "$pace" -ge "$pace_far_ahead_from" ]; then arrow=$(colour "$colour_light_green" "↑")
      elif [ "$pace" -ge "$pace_ahead_from" ]; then arrow=$(colour "$colour_light_green" "↗")
      elif [ "$pace" -ge "$pace_on_track_from" ]; then arrow=
      elif [ "$pace" -ge "$pace_behind_from" ]; then arrow=$(colour "$colour_yellow" "↘")
      else arrow=$(colour "$colour_red" "↓")
      fi
    fi
    printf ' %s %s%s' "$1" "$(lighten "$(fade "$used" "${used}%")")" "$arrow"
  fi
  if [ "${3:-0}" -gt 0 ]; then printf ' ↻%s' "$(colour "$colour_light_grey" "$(duration "$3")")"; fi
}

# --- Constants -------------------------------------------------------------------------------
esc=$(printf '\033')
readonly esc

# Units.
readonly thousand=1000
readonly million=1000000
readonly ms_per_sec=1000
readonly sec_per_min=60
readonly sec_per_hour=3600
readonly sec_per_day=86400
readonly cents_per_dollar=100
readonly micro_per_cent=10000

# Windows and lifetimes, in seconds.
readonly quota_5h_secs=$((5 * sec_per_hour))
readonly quota_7d_secs=$((7 * sec_per_day))
readonly stale_default_secs=$((15 * sec_per_min))

# 256-colour numbers.
readonly colour_light_green=114
readonly colour_yellow=220
readonly colour_orange=208
readonly colour_red=196
readonly colour_grey=245
readonly colour_light_grey=249
readonly colour_white=255

# Percentage scale of the miss (pct): from where each colour starts, as a percentage.
readonly miss_yellow_from=0
readonly miss_orange_from=50
readonly miss_red_from=80

# The fade from plain to red, for the cache countdown as the lifetime runs out and for the input
# tokens and quota percentages as they fill: the 256-colour numbers from white through yellow and
# orange to red, one step each (see fade_colour).
readonly fade_colours="255 231 230 229 228 227 226 220 214 208 202 196"
readonly fade_steps=12
# The share of the range run out where the fade reaches red, and stays there.
readonly fade_red_at=95

# The cache countdown's icons, from the empty circle to the full one, by the share of the lifetime
# left: the fill nearest to what is left (see pie).
readonly ttl_icons="󰝦 󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥"
readonly ttl_icon_count=9

# Pace arrows: the share of quota left over the share of the window left, times 100.
readonly pace_far_ahead_from=150
readonly pace_ahead_from=115
readonly pace_on_track_from=87
readonly pace_behind_from=67

# What the payload may leave out stays empty.
session_id=; prompt_id=; model=; effort=; ctx_used=; ctx_size=
tok_in=; tok_write=; tok_out=; cost=; api_ms=; wall_ms=
five_used=; five_reset=; week_used=; week_reset=
has_cache=; cache_ttl=; miss_total=; miss_cause=; expires_at=

command -v jq >/dev/null 2>&1 || { printf '%s\n' 'statusline: jq is required'; exit 0; }
eval "$(jq -r '
def s: if . == null then "" else tostring end;
def int: if type == "number" and . >= 0 and . < 1e15 then floor | tostring else "" end;
def dec: if type == "number" and . >= 0 and . < 1e15 then tostring else "" end;
@sh "session_id=\(.session_id? | s)
prompt_id=\(.prompt_id? | s)
model=\(.model.display_name? | s)
effort=\(.effort.level? | s)
ctx_used=\(.context_window.used_percentage? | dec)
ctx_size=\(.context_window.context_window_size? | int)
tok_in=\(.context_window.total_input_tokens? | int)
tok_write=\(.context_window.current_usage.cache_creation_input_tokens? | int)
tok_out=\(.context_window.current_usage.output_tokens? | int)
cost=\(.cost.total_cost_usd? | dec)
api_ms=\(.cost.total_api_duration_ms? | int)
five_used=\(.rate_limits.five_hour.used_percentage? | dec)
five_reset=\(.rate_limits.five_hour.resets_at? | int)
week_used=\(.rate_limits.seven_day.used_percentage? | dec)
week_reset=\(.rate_limits.seven_day.resets_at? | int)
has_cache=\(if .prompt_cache? then "1" else "" end)
cache_ttl=\(.prompt_cache.ttl? | s)
miss_total=\(.prompt_cache.miss_recache_tokens? | int)
miss_cause=\((.prompt_cache.last_miss_cause.causes? // []) | join(","))
expires_at=\(.prompt_cache.expires_at? | int)
wall_ms=\(.cost.total_duration_ms? | int)"' 2>/dev/null)"

now=$(date +%s)
readonly now

stale_secs="${CLAUDE_QUOTA_STALE_SECS:-$stale_default_secs}"
case "$stale_secs" in ''|*[!0-9]*) stale_secs=$stale_default_secs ;; esac
readonly stale_secs

# --- State: the turn so far, and how long ago this session last heard from the API ------
state="${CLAUDE_STATUSLINE_STATE_DIR:-/tmp}/claude-statusline-compact-${session_id:-default}.txt"
readonly state
turn_micro=0; turn_miss=0; stale=; dirty=
s_prompt=; s_base=; s_prev=; s_miss=; s_rl=; s_rl_at=
if [ -r "$state" ]; then
  { read -r s_prompt || :; read -r s_base || :; read -r s_prev || :
    read -r s_miss || :; read -r s_rl || :; read -r s_rl_at || :; } < "$state"
fi
case "$s_base" in *[!0-9]*) s_base= ;; esac
case "$s_prev" in ''|*[!0-9]*) s_prev=0 ;; esac
case "$s_rl_at" in ''|*[!0-9]*) s_rl_at=$now ;; esac
if [ -n "$cost" ]; then
  cost_micro=$(usd_to_micro "$cost")
  miss_now=${miss_total:-0}
  case "$s_miss" in ''|*[!0-9]*) s_miss=$miss_now ;; esac
  if [ "$s_prompt" != "$prompt_id" ] || [ -z "$s_base" ]; then
    # A new prompt: the turn that just ended is the previous one (zero if /clear reset the cost).
    if [ -n "$s_base" ]; then
      s_prev=$((cost_micro - s_base)); [ "$s_prev" -lt 0 ] && s_prev=0
    fi
    s_prompt=$prompt_id; s_base=$cost_micro; s_miss=$miss_now; dirty=1
  fi
  turn_micro=$((cost_micro - s_base)); [ "$turn_micro" -lt 0 ] && turn_micro=0
  # Until the new turn bills something, the last one's price stands.
  [ "$turn_micro" -gt 0 ] || turn_micro=$s_prev
  turn_miss=$((miss_now - s_miss))
fi
# Every response bills something, so a cost or quota that moved means one landed. The
# quota alone would not do: it can sit at the same percent through many responses.
if [ -n "$five_used$week_used" ]; then
  rl_key="$cost $five_used ${five_reset:-0} $week_used ${week_reset:-0}"
  if [ "$s_rl" != "$rl_key" ]; then s_rl=$rl_key; s_rl_at=$now; dirty=1
  elif [ $((now - s_rl_at)) -gt "$stale_secs" ]; then stale=1
  fi
fi
if [ -n "$dirty" ]; then
  mkdir -p "${state%/*}" 2>/dev/null || :
  printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$s_prompt" "$s_base" "$s_prev" "$s_miss" "$s_rl" "$s_rl_at" \
    2>/dev/null > "$state" || :
fi

case "$effort" in
  low) effort_abbr=l ;;
  medium) effort_abbr=m ;;
  high) effort_abbr=h ;;
  xhigh) effort_abbr=xh ;;
  max) effort_abbr=x ;;
  *) effort_abbr=$effort ;;
esac

# The model family by its initial and no separators: "Sonnet 5.5" with effort "high" is "S5.5h".
model_abbr=$(colour "$colour_light_grey" "${model:-Claude}")
case $model in
  Sonnet\ *|Opus\ *|Haiku\ *|Fable\ *)
    model_abbr="$(colour "$colour_white" "$(printf '%.1s' "$model")")$(colour "$colour_light_grey" "${model#* }")" ;;
esac
line="$model_abbr${effort_abbr}"
if [ -n "$tok_in" ]; then
  # fade leaves the figure plain until its first step, or with no percentage yet: light grey then.
  line="$line ↑$(lighten "$(fade "$ctx_used" "$(shorten "$tok_in")")")"
  [ -z "$ctx_size" ] || line="$line/$(shorten "$ctx_size")"
fi
# The cache's figures in one bracket: what the last response wrote, the lifetime left and,
# on a turn that missed, the miss. The countdown is coloured as it runs out.
countdown=
ttl_icon=
if [ -n "$has_cache" ]; then
  left=0
  [ -n "$expires_at" ] && left=$((expires_at - now))
  if [ "$left" -gt 0 ]; then
    countdown=$(duration "$left")
    # Faded from plain to red as the lifetime runs out. Without a known TTL there is no share to
    # fade by, and it stays plain.
    cache_ttl_secs=$(duration_to_secs "$cache_ttl")
    share=100
    [ -n "$cache_ttl_secs" ] && share=$(( left * 100 / cache_ttl_secs ))
    countdown_colour=$(fade_colour $((100 - share)))
    [ -z "$countdown_colour" ] || countdown=$(colour "$countdown_colour" "$countdown")
    ttl_icon=$(pie "$share")   # a pie that empties with the lifetime
  else
    # Past the expiry: by how much, in red like the last step of the fade. Without an expiry in
    # the payload there is nothing to count.
    overdue=expired
    [ -n "$expires_at" ] && overdue="-$(duration $((0 - left)))"
    countdown=$(colour "$colour_red" "$overdue")
    ttl_icon=$(pie 0)
  fi
fi
# Only when this turn's requests re-processed cacheable content: its tokens and likely
# cause. Never plain, to stand out among the calm figures: coloured by the share of the
# context re-cached (yellow too when that is unknown).
miss_str=
if [ "$turn_miss" -gt 0 ]; then
  miss_share=0
  [ "${tok_in:-0}" -gt 0 ] && miss_share=$((turn_miss * 100 / tok_in))
  miss_str=$(pct "$miss_share" "miss: $(shorten "$turn_miss")${miss_cause:+ $miss_cause}" \
    "$miss_yellow_from" "$miss_orange_from" "$miss_red_from")
fi
bracket=
[ -n "$tok_write" ] && bracket="+$(shorten "$tok_write")"
[ -n "$countdown" ] && bracket="${bracket:+$bracket, }$ttl_icon$countdown"
[ -n "$miss_str" ] && bracket="${bracket:+$bracket, }$miss_str"
[ -n "$bracket" ] && line="$line ($bracket)"
[ -n "$tok_out" ] && line="$line ↓$(shorten "$tok_out")"
if [ -n "$cost" ]; then
  session_cost=$(colour "$colour_light_grey" "$(micro_to_usd "$cost_micro")")
  if [ "$turn_micro" -gt 0 ]; then line="$line $(micro_to_usd "$turn_micro") ⊂ $session_cost"
  else line="$line $session_cost"
  fi
fi
# The time on the API, then the session's, which contains it: "⚙15m/2h00".
times=
[ -n "$api_ms" ] && times="⚙$(duration $((api_ms / ms_per_sec)))"
[ -n "$wall_ms" ] && times="${times:+$times/}$(duration $((wall_ms / ms_per_sec)))"
[ -z "$times" ] || line="$line $times"
five_left=; [ -z "$five_reset" ] || five_left=$((five_reset - now))
week_left=; [ -z "$week_reset" ] || week_left=$((week_reset - now))
five_str=$(quota ⧖ "$five_used" "$five_left" "$quota_5h_secs" "$stale")
[ -z "$five_str" ] || line="$line$five_str"
line="$line$(quota ▦ "$week_used" "$week_left" "$quota_7d_secs" "$stale")"
printf '%s\n' "$line"
