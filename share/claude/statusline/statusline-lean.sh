#!/bin/sh
# Claude Code status line, lean edition: "Opus 5.5h+ 42%/200K ↑87K ↓340 (f2 r84K w478) cache 42m→104K miss 202K ttl_expired_5m/2,tools_changed/1 api 4m $1.23 12m 5h 37%↻2h10 7d 48%↻4d3h | session name"
#   - model name, with the effort glued on: low -> l, medium -> m, high -> h, xhigh -> h+,
#     max -> x (left out when the model has no effort setting)
#   - share of the context window used, coloured by how full it is: green < 20%, light
#     green < 40%, yellow < 60%, orange < 80%, else red (left out early in a session),
#     then "/" and the window size
#   - ↑ total input tokens, ↓ output tokens, of the last response, then the input's
#     split as (f fresh, r cache read, w cache write); the split is left out while
#     `current_usage` is null
#   - prompt cache: the time left before it goes cold, then "→" and the tokens a cold start
#     would re-cache (cache 42m→104K; the tokens are left out when not reported), or
#     "cold" once the time has run out or there is none. Left out until the first
#     response. The countdown needs a statusline refreshInterval. It stays plain while
#     half the TTL or more is left, then runs from yellow through orange to red (a
#     truecolor gradient, fully red from 15% left) as the cache is about to expire;
#     "cold" is red. It stays plain when the payload has no TTL. `prompt_cache.warm` is
#     not used: it stays true past the expiry until the next response. Once a cache miss
#     has happened it adds, in red, the tokens the misses re-cached and the likely causes
#     with how many misses each explains (miss 202K ttl_expired_5m/2,tools_changed/1);
#     the last miss's cause stands in when no tally is reported.
#   - time spent waiting on the API, session cost in USD, then the wall-clock time the
#     session has run (each duration as 45s, 12m, 3h05, 2d4h)
#   - 5-hour and 7-day quota used, "↻" and the time left until it resets (5h 37%↻2h10 7d
#     48%↻4d3h); the countdown is left out once the reset time has passed
#   - session name, always last (left out when there is none)

eval "$(jq -r '
def s: if . == null then "" else tostring end;
@sh "model=\(.model.display_name? | s)
effort=\(.effort.level? | s)
used=\(.context_window.used_percentage? | s)
size=\(.context_window.context_window_size? | s)
tok_in=\(.context_window.total_input_tokens? | s)
tok_fresh=\(.context_window.current_usage.input_tokens? | s)
tok_read=\(.context_window.current_usage.cache_read_input_tokens? | s)
tok_write=\(.context_window.current_usage.cache_creation_input_tokens? | s)
tok_out=\(.context_window.current_usage.output_tokens? | s)
cost=\(.cost.total_cost_usd? | s)
api_ms=\(.cost.total_api_duration_ms? | s)
five=\(.rate_limits.five_hour.used_percentage? | s)
five_reset=\(.rate_limits.five_hour.resets_at? | s)
week=\(.rate_limits.seven_day.used_percentage? | s)
week_reset=\(.rate_limits.seven_day.resets_at? | s)
cache=\(if .prompt_cache? then "1" else "" end)
ttl=\(.prompt_cache.ttl? | s)
miss_tokens=\(.prompt_cache.miss_recache_tokens? | s)
miss_tally=\((.prompt_cache.miss_causes? // {}) | to_entries | sort_by(-.value) | map("\(.key)/\(.value)") | join(","))
miss_cause=\((.prompt_cache.last_miss_cause.causes? // []) | join(","))
recache=\(.prompt_cache.recache_tokens_if_cold? | s)
warm_until=\(.prompt_cache.expires_at? | s)
dur_ms=\(.cost.total_duration_ms? | s)
session=\(.session_name? | s)"' 2>/dev/null)"

# tokens N -> "340", "1.2K", "15K", "1.2M"
tokens() {
  if [ "$1" -ge 1000000 ]; then
    _t=$((($1 + 50000) / 100000)); echo "$((_t / 10)).$((_t % 10))M"
  elif [ "$1" -ge 10000 ]; then echo "$((($1 + 500) / 1000))K"
  elif [ "$1" -ge 1000 ]; then
    _t=$((($1 + 50) / 100)); echo "$((_t / 10)).$((_t % 10))K"
  else echo "$1"
  fi
}

ESC=$(printf '\033')
# Truecolor stops of the cache countdown as it runs out (r g b).
WARN_YELLOW='250 210 60'; WARN_ORANGE='255 140 30'; WARN_RED='235 50 40'

# span SECONDS -> "45s", "12m", "3h05", "2d4h"
span() {
  if [ "$1" -ge 86400 ]; then printf '%dd%dh' $(($1 / 86400)) $((($1 % 86400) / 3600))
  elif [ "$1" -ge 3600 ]; then printf '%dh%02d' $(($1 / 3600)) $((($1 % 3600) / 60))
  elif [ "$1" -ge 60 ]; then printf '%dm' $(($1 / 60))
  else printf '%ds' "$1"
  fi
}

case "$effort" in
  low) e=l ;;
  medium) e=m ;;
  high) e=h ;;
  xhigh) e=h+ ;;
  max) e=x ;;
  *) e= ;;
esac

line="${model:-Claude}${e}"
if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  if [ "$pct" -lt 20 ]; then c=34
  elif [ "$pct" -lt 40 ]; then c=114
  elif [ "$pct" -lt 60 ]; then c=220
  elif [ "$pct" -lt 80 ]; then c=208
  else c=196
  fi
  line="$line ${ESC}[38;5;${c}m${pct}%${ESC}[0m"
  if [ -n "$size" ]; then
    if [ "$size" -ge 1000000 ]; then line="$line/$((size / 1000000))M"
    else line="$line/$((size / 1000))K"
    fi
  fi
fi
[ -n "$tok_in" ] && line="$line ↑$(tokens "$tok_in")"
[ -n "$tok_out" ] && line="$line ↓$(tokens "$tok_out")"
[ -n "$tok_fresh" ] && [ -n "$tok_read" ] && [ -n "$tok_write" ] \
  && line="$line (f$(tokens "$tok_fresh") r$(tokens "$tok_read") w$(tokens "$tok_write"))"
if [ -n "$cache" ]; then
  left=0
  [ -n "$warm_until" ] && left=$((${warm_until%%.*} - $(date +%s)))
  if [ "$left" -gt 0 ]; then
    # Without a known TTL there is no share to colour by: the countdown stays plain.
    case "$ttl" in 1h) ttl_secs=3600 ;; 5m) ttl_secs=300 ;; *) ttl_secs= ;; esac
    if [ -n "$ttl_secs" ]; then
      share=$(( left * 100 / ttl_secs ))
      if [ "$share" -ge 50 ]; then
        line="$line cache $(span "$left")"
      else
        # Piecewise-linear RGB: yellow at 50% left, orange at 32%, red at 15% and below.
        if [ "$share" -ge 32 ]; then lo=$WARN_ORANGE; hi=$WARN_YELLOW; t=$(( (share - 32) * 100 / 18 ))
        elif [ "$share" -ge 15 ]; then lo=$WARN_RED; hi=$WARN_ORANGE; t=$(( (share - 15) * 100 / 17 ))
        else lo=$WARN_RED; hi=$WARN_RED; t=0
        fi
        set -- $lo $hi
        c="$(( $1 + ($4 - $1) * t / 100 ));$(( $2 + ($5 - $2) * t / 100 ));$(( $3 + ($6 - $3) * t / 100 ))"
        line="$line cache ${ESC}[38;2;${c}m$(span "$left")${ESC}[0m"
      fi
    else
      line="$line cache $(span "$left")"
    fi
  else line="$line cache ${ESC}[38;2;235;50;40mcold${ESC}[0m"
  fi
  [ -n "$recache" ] && line="${line}→$(tokens "${recache%%.*}")"
  # Red, only once a miss has re-processed cacheable content: its tokens and likely cause.
  if [ "${miss_tokens%%.*}" -gt 0 ] 2>/dev/null; then
    miss_what=${miss_tally:-$miss_cause}
    line="$line ${ESC}[38;2;235;50;40mmiss $(tokens "${miss_tokens%%.*}")${miss_what:+ $miss_what}${ESC}[0m"
  fi
fi
[ -n "$api_ms" ] && line="$line api $(span $((${api_ms%%.*} / 1000)))"
[ -n "$cost" ] && line="$line \$$(printf '%.2f' "$cost")"
[ -n "$dur_ms" ] && line="$line $(span $((${dur_ms%%.*} / 1000)))"
# quota LABEL USED RESET_EPOCH -> appends "5h 37%↻2h10"
quota() {
  [ -n "$2" ] || return
  line="$line $1 $(printf '%.0f' "$2")%"
  if [ -n "$3" ]; then
    left=$((${3%%.*} - $(date +%s)))
    [ "$left" -gt 0 ] && line="${line}↻$(span "$left")"
  fi
}
quota 5h "$five" "$five_reset"
quota 7d "$week" "$week_reset"
printf '%s\n' "$line${session:+ | $session}"
