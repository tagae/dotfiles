#!/bin/sh
# Claude Code status line:
#   "Model+effort ctx [+{subagents}] 5h-quota spend folder[@branch] weekly-quota"
#
# Segments run from fastest-moving to slowest, so the eye can stop as soon as it has
# what it came for, and the static weekly figure is what a narrow terminal cuts off.
#
# MAINTENANCE RULE: README.md next to this script describes what it shows. Change both
# in the same commit.

# File mtime(s) as epoch seconds. GNU spelling FIRST: GNU's `stat -f` exits 1 yet still
# prints a block to stdout, which would land in the caller's variable.
file_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }
files_mtime() { stat -c '%Y %n' "$@" 2>/dev/null || stat -f '%m %N' "$@" 2>/dev/null; }
# pct_left USED -> $_p = 100 - USED, rounded.
pct_left() { _p=$(awk -v u="$1" 'BEGIN { printf "%.0f", 100 - u }'); }
# tokens N -> "202K", "1.2M" (rounded, no fork).
tokens() {
  if [ "$1" -ge 1000000 ]; then
    _t=$((($1 + 50000) / 100000)); echo "$((_t / 10)).$((_t % 10))M"
  else
    echo "$((($1 + 500) / 1000))K"
  fi
}

input=$(cat)
# Every field in ONE jq: with refreshInterval 1, a jq per field was fourteen processes a
# second. `// ""` rather than `// empty`, which would blank the whole string; the `?`s
# keep one malformed field from blanking the others.
eval "$(printf '%s' "$input" | jq -r '@sh "session_id=\(.session_id // "")
model=\(.model.display_name? // "Claude" | sub(" context\\)"; ")"))
effort=\(.effort.level? // "")
ctx=\(.context_window.used_percentage? // "")
total=\(.context_window.context_window_size? // "")
prompt_id=\(.prompt_id // "")
pc_ttl=\(.prompt_cache.ttl? // "")
pc_expires=\(.prompt_cache.expires_at? // "")
pc_recache=\(.prompt_cache.recache_tokens_if_cold? // "")
pc_missed=\(.prompt_cache.miss_recache_tokens? // "")
pc_cause=\((.prompt_cache.last_miss_cause.causes? // []) | join(","))
five=\(.rate_limits.five_hour.used_percentage? // "")
reset=\(.rate_limits.five_hour.resets_at? // "")
week=\(.rate_limits.seven_day.used_percentage? // "")
week_reset=\(.rate_limits.seven_day.resets_at? // "")
cost=\(.cost.total_cost_usd? // "")
tp=\(.transcript_path // "")
cwd=\(.workspace.current_dir? // .cwd // "")"' 2>/dev/null)"
# One wall clock per render: every age, countdown and blink phase agrees.
now=$(date +%s)
[ -n "$cost" ] || cost=0
[ -n "$cwd" ] || cwd=$PWD

# Off unless ~/.claude/statusline-debug exists: logs what each terminal was handed and
# rendered. Quota bugs were terminals disagreeing, unreproducible after the fact.
DEBUG_LOG=""
[ -f "$HOME/.claude/statusline-debug" ] && DEBUG_LOG="$HOME/.claude/statusline-debug.log"
[ -n "$DEBUG_LOG" ] && printf '%s' "$input" | jq -c --arg t "$now" \
  '{t:$t,sid:(.session_id//""|.[0:8]),rl:.rate_limits}' >> "$DEBUG_LOG" 2>/dev/null

# --- Quota: merged across terminals ----------------------------------------------
# `rate_limits` caches THIS session's last response headers, so an idle terminal shows
# frozen numbers. quota-state.sh merges every terminal's reading. A payload that changed
# since this session's previous render is fresh: a new response landed.
fresh=0
if [ -n "$five" ]; then
  rl_now="$five ${reset:-0} ${week:-} ${week_reset:-0}"
  rl_seen="/tmp/claude-statusline-rl-${session_id:-default}.txt"
  rl_prev=""
  [ -r "$rl_seen" ] && read -r rl_prev < "$rl_seen"
  [ "$rl_prev" = "$rl_now" ] || { fresh=1; printf '%s' "$rl_now" > "$rl_seen"; }
fi
merged=$("$HOME/.claude/hooks/quota-state.sh" publish \
  "${five:-}" "${reset:-0}" "${week:-}" "${week_reset:-0}" "$fresh" 2>/dev/null)
five_age=""
if [ -n "$merged" ]; then
  # Fields 6-8: the tightest per-model weekly cap (Fable's), its model and its reset.
  # Only the probe knows it; `rate_limits` never carries it.
  read -r m_five m_reset m_week m_week_reset m_meas wscoped wscoped_label wscoped_reset _ <<EOF
$merged
EOF
  if [ "$m_five" != "-1" ]; then
    five=$m_five; reset=$m_reset
    case "$m_meas" in ''|*[!0-9]*|0) five_age=999999 ;;
      *) five_age=$((now - m_meas)); [ "$five_age" -lt 0 ] && five_age=0 ;;
    esac
  fi
  if [ -n "$m_week" ] && [ "$m_week" != "-1" ]; then
    week=$m_week; week_reset=$m_week_reset
  fi
fi
# A cache cannot notice an allowance that GREW (a plan upgrade), so every
# CLAUDE_QUOTA_PROBE_SECS some render kicks quota-probe.sh in the background to ask the
# account itself. The probe locks, so racing renders send one request.
probe_secs="${CLAUDE_QUOTA_PROBE_SECS:-${CLAUDE_WEEKLY_QUOTA_PROBE_SECS:-300}}"
case "$probe_secs" in ''|*[!0-9]*|0) probe_secs=300 ;; esac
probe_at=0
[ -r "${CLAUDE_QUOTA_PROBE_FILE:-$HOME/.claude/quota-probe}" ] \
  && read -r probe_at _ < "${CLAUDE_QUOTA_PROBE_FILE:-$HOME/.claude/quota-probe}"
case "$probe_at" in ''|*[!0-9]*) probe_at=0 ;; esac
if [ "$((now - probe_at))" -ge "$probe_secs" ] && [ -x "$HOME/.claude/hooks/quota-probe.sh" ]; then
  nohup "$HOME/.claude/hooks/quota-probe.sh" >/dev/null 2>&1 </dev/null &
fi
# Past this nobody has re-confirmed the 5h figure: still shown, but marked "?".
STALE_5H="${CLAUDE_QUOTA_STALE_SECS:-900}"

# --- Colours ---------------------------------------------------------------------
ESC=$(printf '\033')
RESET="${ESC}[0m"
RED="${ESC}[31m"
ORANGE="${ESC}[38;5;208m"
BLUE="${ESC}[38;5;111m"
GREEN="${ESC}[38;5;78m"
TEAL="${ESC}[38;5;80m"   # nearest 256-colour match to Claude Code's prompt border

# Light or dark follows Claude Code's own theme: `theme` in settings.json, or the
# `base` of a `custom:<name>` theme. `auto` follows the terminal background, which a
# status line cannot query (no tty); $COLORFGBG ("fg;bg") stands in, else the macOS
# appearance, else dark. CLAUDE_STATUSLINE_LIGHT=0/1 overrides.
# json_str FILE KEY -> $_json_val: the first `"KEY": "value"` in FILE. Builtins only.
json_str() {
  _json_val=''
  [ -r "$1" ] || return 1
  while IFS= read -r _l || [ -n "$_l" ]; do
    case "$_l" in *"\"$2\""*) ;; *) continue ;; esac
    _l=${_l#*"\"$2\""}; _l=${_l#*\"}; _json_val=${_l%%\"*}
    return 0
  done < "$1"
  return 1
}
LIGHT_UI="${CLAUDE_STATUSLINE_LIGHT:-}"
if [ -z "$LIGHT_UI" ]; then
  LIGHT_UI=0
  json_str "$HOME/.claude/settings.json" theme
  case "$_json_val" in
    light*) LIGHT_UI=1 ;;
    auto)
      case "${COLORFGBG:-}" in
        *\;7|*\;9|*\;1[0-5]) LIGHT_UI=1 ;;   # white or bright background
        *\;*) ;;
        *) # AppleInterfaceStyle is "Dark" in dark mode and unset in light mode.
           command -v defaults >/dev/null 2>&1 \
             && ! defaults read -g AppleInterfaceStyle >/dev/null 2>&1 && LIGHT_UI=1 ;;
      esac ;;
    custom:*)
      json_str "$HOME/.claude/themes/${_json_val#custom:}.json" base
      case "$_json_val" in light*) LIGHT_UI=1 ;; esac ;;
  esac
fi
if [ "$LIGHT_UI" = 1 ]; then
  ORANGE="${ESC}[38;5;166m"
  BLUE="${ESC}[38;5;25m"
  GREEN="${ESC}[38;5;28m"
  TEAL="${ESC}[38;5;30m"
fi

# pulse red|orange TEXT: blink, one second on, one off. Two states register in
# peripheral vision where a gradient does not; the shared clock keeps blinks in unison.
pulse() {
  if [ $((now % 2)) -eq 0 ]; then
    case "$1" in red) printf '%s%s%s' "$RED" "$2" "$RESET" ;; *) printf '%s%s%s' "$ORANGE" "$2" "$RESET" ;; esac
  else
    printf '%s' "$2"
  fi
}
# paint_low LEFT TEXT -> $_pl: TEXT in red under 5% left, orange under 15%.
paint_low() {
  if [ "$1" -lt 5 ]; then _pl="${RED}$2${RESET}"
  elif [ "$1" -lt 15 ]; then _pl="${ORANGE}$2${RESET}"
  else _pl=$2
  fi
}
# Effort as a lower-case suffix ("Opus 5m"); "max" stays spelled out since "m" is medium.
# Mirrored by eff() in the subagent chip.
abbr_effort() {
  case "$1" in low) echo l ;; medium) echo m ;; high) echo h ;; xhigh) echo xh ;; *) echo "$1" ;; esac
}

# --- Turn state: working or idle, and for how long --------------------------------
# Without a readable transcript neither is known: the turn's figure shows with no age.
idle=1; age_secs=""; sid=""
if [ -n "$tp" ] && [ -f "$tp" ]; then
  # Idle = the last main-chain reply did not stop for a tool and nothing user-side came
  # after it. No apostrophes inside: this is one single-quoted shell string.
  tok_prog='
. as $all
| ([ range(0; ($all|length)) as $i | select($all[$i].type=="assistant" and ($all[$i].isSidechain != true)) | $i ] | last) as $lastA
| ($lastA != null
   and (($all[$lastA].message.stop_reason // "") != "tool_use")
   and ([ range(($lastA + 1); ($all|length)) as $j
          | select($all[$j].type=="user" and ($all[$j].isSidechain != true) and ($all[$j].isMeta != true)) ] | length) == 0
  ) as $idle
| ([ $all[] | select(.type=="assistant" and (.isSidechain != true)) | .timestamp // empty ] | last) as $last_ts
| (try ($last_ts | sub("\\.[0-9]+"; "") | sub("Z?$"; "Z") | fromdateiso8601) catch "") as $last_epoch
| "\($last_epoch)|\(if $idle then 1 else 0 end)"'
  sid=${tp##*/}; sid=${sid%.jsonl}
  # Slurping a multi-MB transcript every second is too costly: the one-line result is
  # cached while the file's mtime holds. "|"-separated, since `read` would collapse an
  # empty tab-separated field.
  cache="/tmp/claude-statusline-cache-v6-${sid}.txt"
  mtime=$(file_mtime "$tp")
  cached_mtime=""; tok_line=""
  [ -f "$cache" ] && { read -r cached_mtime; read -r tok_line; } < "$cache"
  if [ -z "$tok_line" ] || [ "$cached_mtime" != "$mtime" ]; then
    # TZ=UTC: jq 1.6 (Debian 12) leaks local DST into fromdateiso8601.
    tok_line=$(TZ=UTC jq -s -r "$tok_prog" "$tp" 2>/dev/null)
    printf '%s\n%s\n' "$mtime" "$tok_line" > "$cache"
  fi
  IFS='|' read -r last_epoch idle _ <<EOF
$tok_line
EOF
  : "${idle:=1}"
  case "$last_epoch" in
    ''|*[!0-9]*) ;;
    *) age_secs=$((now - last_epoch)); [ "$age_secs" -lt 0 ] && age_secs=0 ;;
  esac
fi

# --- Turn baseline -----------------------------------------------------------------
# A turn starts when `prompt_id` changes. The session's running totals are snapshotted
# then, and the turn's figures are the growth since: its cost (`total_cost_usd`, which
# matches /usage and includes subagents) and the tokens its cache misses rebuilt. The
# finished turn's cost is kept, to show until the new turn bills something.
# sub0 A B -> $_d = A - B, floored at 0. bc, NOT awk: awk's doubles round a tiny real
# change (0.3 -> 0.30000000000000004) to zero ("tiny cost change" in the tests).
sub0() { _d=$(echo "$1 - $2" | bc -l); case "$_d" in -*) _d=0 ;; esac; }
case "$pc_missed" in ''|*[!0-9]*) pc_missed=0 ;; esac
state="/tmp/claude-statusline-turn-v2-${session_id:-default}.txt"
prev_key=""; base=""; prev_turn_cost=""; base_missed=""
[ -f "$state" ] && { read -r prev_key; read -r base; read -r prev_turn_cost; read -r base_missed; } < "$state"
if [ "$prev_key" != "$prompt_id" ] || [ -z "$base" ]; then
  [ -n "$base" ] && { sub0 "$cost" "$base"; prev_turn_cost=$_d; }
  base=$cost; base_missed=$pc_missed
  printf '%s\n%s\n%s\n%s\n' "$prompt_id" "$cost" "$prev_turn_cost" "$pc_missed" > "$state"
fi
sub0 "$cost" "$base"; turn_cost=$_d
: "${prev_turn_cost:=0}"
case "$base_missed" in ''|*[!0-9]*) base_missed=$pc_missed ;; esac
case "$turn_cost" in *[1-9]*) turn_billed=1 ;; *) turn_billed=0 ;; esac

# --- Prompt cache, as Claude Code reports it -----------------------------------------
# Tokens, not dollars: rates change with every model, a token count never goes stale.
case "$pc_ttl" in 1h) ttl=1h; ttl_secs=3600 ;; *) ttl=5m; ttl_secs=300 ;; esac
pc_expires=${pc_expires%%.*}
fc_tokens=${pc_recache%%.*}   # what the next message rebuilds if the cache goes cold
case "$fc_tokens" in ''|*[!0-9]*) fc_tokens=0 ;; esac
# Blink only when the rebuild is big enough to move for: export CLAUDE_MISS_FLOOR=500000
MISS_FLOOR="${CLAUDE_MISS_FLOOR:-200000}"
# Where the cached prefix stands, while idle (a working agent keeps it warm).
# `expires_at` counts from the START of the last request, so it is exact where an idle
# clock counted from the last reply runs late.
#   expiring = last fifth of the TTL: send something now and keep it
#   expired  = the next message rebuilds the prefix
phase=none
if [ "$idle" = 1 ]; then
  case "$pc_expires" in
    ''|*[!0-9]*) ;;
    *) if [ "$pc_expires" -le "$now" ]; then phase=expired
       elif [ $((pc_expires - now)) -le $((ttl_secs / 5)) ]; then phase=expiring
       fi ;;
  esac
fi
big_miss=""; [ "$fc_tokens" -gt "$MISS_FLOOR" ] && big_miss=1

# --- Subagents in flight: "+{O5h×2,S5m}" ----------------------------------------------
# What each running subagent runs on, grouped: Claude Code's own list names agents but
# not their model, which is what decides a fan-out's cost.
# SOURCE: <session>/subagents/agent-<id>.meta.json (toolUseId, model alias, name,
# parentAgentId) and agent-<id>.jsonl (the agent's transcript: model and effort).
# STOPPED = the transcript it reports to (the session's, or its parent agent's) has
# recorded it: its toolUseId as a tool_result or in <tool-use-id>, or its agentId in
# <task-id>. An async launch receipt is not a stop, and a forked skill has no
# toolUseId, so its agentId is its key. A stop is not final: SendMessage wakes an agent,
# which then writes to its own transcript. So an agent is idle when its latest stop is
# no older than its last line, give or take $SUB_SLACK. Stops are remembered in /tmp
# because a busy session scrolls them out of the scanned tail.
SUB_STALE="${CLAUDE_SUB_STALE:-900}"   # s of silence before an agent counts as dead
SUB_TAIL="${CLAUDE_SUB_TAIL:-2000000}" # bytes of each reporting transcript scanned
SUB_SLACK="${CLAUDE_SUB_SLACK:-5}"     # s a stop may precede the agent's last line
sub_render=""
_sdir="${tp%.jsonl}/subagents"
if [ -n "$sid" ] && [ -d "$_sdir" ]; then
  _fresh=""
  while IFS=' ' read -r _mt _p; do
    case "$_mt" in ''|*[!0-9]*) continue ;; esac
    [ $((now - _mt)) -le "$SUB_STALE" ] || continue
    _i=${_p##*/agent-}; _fresh="$_fresh,${_i%.jsonl}"
  done <<EOF
$(files_mtime "$_sdir"/agent-*.jsonl)
EOF
  # "id key alias name parent" per fresh agent, "-" for an absent field. The alias
  # ("opus") only stands in until the agent's first reply names the real model.
  _meta=""
  [ -n "$_fresh" ] && _meta=$(awk -v want="$_fresh" '
      BEGIN { n = split(want, a, ","); for (i = 1; i <= n; i++) if (a[i] != "") w[a[i]] = 1 }
      function field(k,   v) { v = ""; if (match($0, "\"" k "\":\"[^\"]*\"")) v = substr($0, RSTART + length(k) + 4, RLENGTH - length(k) - 5); return v }
      {
        id = FILENAME; sub(/.*\/agent-/, "", id); sub(/\.meta\.json$/, "", id)
        if (!(id in w) || (id in seen)) next
        seen[id] = 1
        t = field("toolUseId"); m = field("model"); nm = field("name"); pa = field("parentAgentId")
        if (t == "") t = id
        print id " " t " " (m == "" ? "-" : m) " " (nm == "" ? "-" : nm) " " (pa == "" ? "-" : pa)
      }' "$_sdir"/agent-*.meta.json 2>/dev/null)
  _running=""
  if [ -n "$_meta" ]; then
    set --
    for _i in $(printf '%s' "$_fresh" | tr ',' ' '); do set -- "$@" "$_sdir/agent-$_i.jsonl"; done
    _last=$(tail -q -n 1 "$@" 2>/dev/null)   # each agent's last line
    set -- "$tp"                               # the transcripts agents stop into
    for _pa in $(printf '%s\n' "$_meta" | awk '$5 != "-" && !s[$5]++ { print $5 }'); do
      [ -r "$_sdir/agent-$_pa.jsonl" ] && set -- "$@" "$_sdir/agent-$_pa.jsonl"
    done
    _done_file="/tmp/claude-statusline-agentdone-v2-${sid}.txt"
    _done=""
    [ -r "$_done_file" ] && _done=$(cat "$_done_file" 2>/dev/null)
    # Tables go through the environment: awk -v takes one line and expands escapes.
    # Output: "R <id> <alias>" still running; "D <key> <stamp>" a newly seen stop.
    _scan=$(for _f in "$@"; do tail -c "$SUB_TAIL" "$_f" 2>/dev/null; echo; done |
      _meta="$_meta" _done="$_done" _last="$_last" SLACK="$SUB_SLACK" awk '
      # ISO-8601 UTC -> seconds, monotonic but not an epoch (32-day months).
      function iso2n(t) {
        return ((((substr(t, 1, 4) * 12 + substr(t, 6, 2)) * 32 + substr(t, 9, 2)) * 24 \
                + substr(t, 12, 2)) * 3600 + substr(t, 15, 2) * 60 + substr(t, 18))
      }
      # A line s newest UTC timestamp. It may quote older ones, never a later one.
      function stamp(line,   best, s) {
        best = ""
        while (match(line, /"timestamp":"20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9](\.[0-9]+)?Z"/)) {
          s = substr(line, RSTART + 13, RLENGTH - 14)
          if (s > best) best = s
          line = substr(line, RSTART + RLENGTH)
        }
        return best
      }
      function mark_stop(key) { if (ts == "") ts = stamp($0); if (ts > mark[key]) mark[key] = ts }
      BEGIN {
        n = split(ENVIRON["_meta"], rows, "\n")
        for (i = 1; i <= n; i++) {
          if (split(rows[i], f, " ") < 5 || f[2] == "") continue
          live[f[2]] = f[1]; aid[f[1]] = f[2]
          alias[f[1]] = (f[3] == "-") ? "" : f[3]
        }
        n = split(ENVIRON["_done"], d, "\n")
        for (i = 1; i <= n; i++) {
          if (split(d[i], g, " ") < 2 || !(g[1] in live)) continue
          if (g[2] > mark[g[1]]) mark[g[1]] = g[2]
          cached[g[1]] = mark[g[1]]
        }
        n = split(ENVIRON["_last"], d, "\n")
        for (i = 1; i <= n; i++)
          if (match(d[i], /"agentId":"[^"]*"/)) {
            a = substr(d[i], RSTART + 11, RLENGTH - 12)
            if (a in aid) last[a] = stamp(d[i])
          }
      }
      {
        ts = ""
        n = split($0, parts, /"tool_use_id":"/)
        for (i = 2; i <= n; i++) {
          q = index(parts[i], "\""); if (q < 2) continue
          id = substr(parts[i], 1, q - 1)
          if ((id in live) && !index(parts[i], "Async agent launched successfully")) mark_stop(id)
        }
        n = split($0, g, /<tool-use-id>/)
        for (i = 2; i <= n; i++) {
          q = index(g[i], "<"); if (q < 2) continue
          id = substr(g[i], 1, q - 1)
          if (id in live) mark_stop(id)
        }
        n = split($0, k, /<task-id>/)
        for (i = 2; i <= n; i++) {
          q = index(k[i], "<"); if (q < 2) continue
          a = substr(k[i], 1, q - 1)
          if (a in aid) mark_stop(aid[a])
        }
      }
      END {
        for (t in live) {
          id = live[t]
          if (mark[t] != "" && mark[t] != cached[t]) print "D " t " " mark[t]
          if (mark[t] != "" && last[id] != "" && iso2n(mark[t]) >= iso2n(last[id]) - SLACK) continue
          print "R " id " " alias[id]
        }
      }')
    _running=$(printf '%s\n' "$_scan" | sed -n 's/^R //p')
    _newly_done=$(printf '%s\n' "$_scan" | sed -n 's/^D //p')
    [ -n "$_newly_done" ] && { printf '%s\n' "$_newly_done" >> "$_done_file"; } 2>/dev/null
  fi
  if [ -n "$_running" ]; then
    # An agent's model and effort never change: resolved once, remembered in /tmp.
    _ac="/tmp/claude-statusline-agents-v1-${sid}.txt"
    _known="|"
    [ -f "$_ac" ] && while IFS= read -r _line; do
      [ -n "$_line" ] && _known="$_known$_line|"
    done < "$_ac"
    _rows=""
    set --
    while IFS=' ' read -r _id _alias; do
      [ -n "$_id" ] || continue
      case "$_known" in
        *"|$_id "*)
          _hit=${_known#*"|$_id "}
          _rows="$_rows
$_id ${_hit%%"|"*}"
          continue ;;
      esac
      set -- "$@" "$_sdir/agent-$_id.jsonl"
      # Until its transcript says otherwise: the requested alias (else this session's
      # model) and this session's effort, which an agent inherits by default.
      _rows="$_rows
$_id ${_alias:-$model} $effort"
    done <<EOF
$_running
EOF
    if [ "$#" -gt 0 ]; then
      # Both facts sit on the agent's first reply. Effort is optional: Haiku writes none.
      _new=$(awk '
        FNR > 40 { nextfile }
        /"type":"assistant"/ && /"model":"/ {
          id = FILENAME; sub(/.*\/agent-/, "", id); sub(/\.jsonl$/, "", id)
          m = ""; if (match($0, /"model":"[^"]*"/))  m = substr($0, RSTART + 9,  RLENGTH - 10)
          e = ""; if (match($0, /"effort":"[^"]*"/)) e = substr($0, RSTART + 10, RLENGTH - 11)
          if (m != "") { print id " " m " " e; nextfile }
        }' "$@" 2>/dev/null)
      if [ -n "$_new" ]; then
        printf '%s\n' "$_new" >> "$_ac"
        # Last word wins in the aggregator: what the agent ran on beats the guess.
        _rows="$_rows
$_new"
      fi
    fi
    set --
    sub_chip=$(printf '%s\n' "$_rows" | awk '
      # Family initial plus version: "claude-fable-5-1" -> F5.1, "claude-haiku-4-5-20251001"
      # -> H4.5, "Opus 5 (1M)" -> O5, "opus" -> O.
      function abbr(s,   v, i, n, p) {
        s = tolower(s)
        sub(/^claude-/, "", s); sub(/ *\(.*\)$/, "", s); sub(/\[[^]]*\]$/, "", s)
        gsub(/[ _]/, "-", s); sub(/-2[0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/, "", s)
        n = split(s, p, "-")
        v = ""
        for (i = 2; i <= n; i++) v = v (v == "" ? "" : ".") p[i]
        return toupper(substr(p[1], 1, 1)) v
      }
      function eff(e) {
        return e == "low" ? "l" : e == "medium" ? "m" : e == "high" ? "h" : e == "xhigh" ? "xh" : e
      }
      NF >= 2 { mdl[$1] = $2; lvl[$1] = $3 }
      END {
        for (id in mdl) { k = abbr(mdl[id]) eff(lvl[id]); if (!(k in c)) ord[++n] = k; c[k]++ }
        if (!n) exit
        # Biggest group first.
        for (i = 2; i <= n; i++) {
          k = ord[i]
          for (j = i - 1; j >= 1 && (c[ord[j]] < c[k] || (c[ord[j]] == c[k] && ord[j] > k)); j--) ord[j + 1] = ord[j]
          ord[j + 1] = k
        }
        s = ""
        for (i = 1; i <= n; i++) s = s (s == "" ? "" : ",") ord[i] (c[ord[i]] > 1 ? "×" c[ord[i]] : "")
        printf "+{%s}", s
      }')
    [ -n "$sub_chip" ] && sub_render=" ${GREEN}${sub_chip}${RESET}"
  fi
fi

# === The line ========================================================================

# --- Model, effort and context: "Opus 5.5xh 330K" or "Sonnet 5.5h 80K/200K • 40%" -------
# Effort is glued to the name: model and effort are one thought.
model_name=$model
e=$(abbr_effort "$effort")
size_label=""
case "$model" in
  *" ("*) size_label=${model##*(}; size_label=${size_label%)*}; model=${model%% (*} ;;
esac
model="$model$e"
if [ -n "$ctx" ] && [ -n "$total" ]; then
  # Orange from 70% of the window, red from 90%, on any window size.
  ctx_pct=$(printf '%.0f' "$ctx")
  pct_str="$ctx_pct%"
  ctx_col=$BLUE
  [ "$ctx_pct" -ge 70 ] && ctx_col=$ORANGE
  [ "$ctx_pct" -ge 90 ] && ctx_col=$RED
  [ "$ctx_col" = "$BLUE" ] || pct_str="${ctx_col}${pct_str}${RESET}"
  read -r total_label used_label <<EOF
$(awk -v c="$ctx" -v t="$total" 'BEGIN {
  u = sprintf("%.0f", c * t / 100) + 0
  printf "%s %s\n", (t >= 1000000) ? sprintf("%.0fM", t / 1000000) : sprintf("%.0fK", t / 1000),
    (u >= 1000000) ? sprintf("%.2fM", u / 1000000) : (u >= 1000) ? sprintf("%.0fK", u / 1000) : u
}')
EOF
  : "${size_label:=$total_label}"
  # A cache about to cost a big rebuild blinks the count, in step with the idle clock;
  # otherwise its colour is how full the window is.
  case "$phase${big_miss}" in
    expired1)  ctx_str=$(pulse red "$used_label") ;;
    expiring1) ctx_str=$(pulse orange "$used_label") ;;
    *)         ctx_str="${ctx_col}${used_label}${RESET}" ;;
  esac
  # A bare count means a 1M window; smaller ones keep "used/size • N%".
  if [ "$size_label" = 1M ]; then
    model="$model $ctx_str"
  else
    model="$model $ctx_str/$size_label • $pct_str"
  fi
fi
out="${model}${sub_render}"
sep=" | "

# --- Five-hour quota: "↗98% / 1h23", on its own coloured block ------------------------
# The block's ground carries the low-quota alarm: slate (60), amber under 15% left (94),
# maroon under 5% (88); pastels under black text on a light page. Colours inside the
# block re-assert the ground, since a plain reset would punch a hole in it.
if [ -n "$five" ]; then
  pct_left "$five"; left=$_p
  if [ "$left" -lt 5 ] 2>/dev/null; then _qbg=88; _lbg=217
  elif [ "$left" -lt 15 ] 2>/dev/null; then _qbg=94; _lbg=223
  else _qbg=60; _lbg=189
  fi
  if [ "$LIGHT_UI" = 1 ]; then
    _qb="${ESC}[48;5;${_lbg}m"
    QCHIP="${_qb}${ESC}[38;5;16m"; QGREEN="${_qb}${ESC}[38;5;28m"; QORANGE="${_qb}${ESC}[38;5;166m"
    QRED="${_qb}${ESC}[38;5;160m"; QGREY="${_qb}${ESC}[38;5;242m"
  else
    _qb="${ESC}[48;5;${_qbg}m"
    QCHIP="${_qb}${ESC}[38;5;231m"; QGREEN="${_qb}${ESC}[38;5;78m"; QORANGE="${_qb}${ESC}[38;5;208m"
    QRED="${_qb}${ESC}[38;5;203m"; QGREY="${_qb}${ESC}[38;5;248m"
  fi
  ind=""; dur=""
  diff=$((${reset:-0} - now))
  if [ "$diff" -gt 0 ]; then
    # "1h23", not "1:23", which reads as a wall clock.
    if [ "$diff" -ge 3600 ]; then
      dur=$(printf '%dh%02d' $((diff / 3600)) $(((diff % 3600) / 60)))
    else
      dur="$((diff / 60))m"
    fi
    # Burn rate: share of quota left over share of the 5h window left.
    case $(awk -v u="$five" -v d="$diff" 'BEGIN { r = (100 - u) / 100 / (d / 18000)
        print (r >= 1.5) ? "up" : (r >= 1.15) ? "rise" : (r >= 0.87) ? "" : (r >= 0.67) ? "fall" : "down" }') in
      up)   ind="${QGREEN}↑${QCHIP}" ;;
      rise) ind="${QGREEN}↗${QCHIP}" ;;
      fall) ind="${QORANGE}↘${QCHIP}" ;;
      down) ind="${QRED}↓${QCHIP}" ;;
    esac
  fi
  # A reading nobody has re-confirmed lately turns into a grey "?": a frozen
  # early-window figure would otherwise paint a confident green arrow.
  if [ -n "$five_age" ] && [ "$five_age" -gt "$STALE_5H" ] 2>/dev/null; then
    pct_part="${QGREY}${left}%?${QCHIP}"
  else
    pct_part="${ind}${left}%"
  fi
  out="$out ${QCHIP}${pct_part}${dur:+ / $dur}${RESET}"
  sep=" "   # the block's edge separates; no pipe needed
fi

# --- Spend: "$0.1 -3m ⊂ $25" ----------------------------------------------------------
# The turn's cost is contained in ("⊂") the session's. Both are TRUNCATED, never
# rounded, so the turn can never read larger than the session; the +1e-9 defends
# against 3.2*10 = 31.999999999999996.
trunc1() { awk -v v="${1:-0}" 'BEGIN { printf "%.1f", int(v * 10 + 1e-9) / 10 }'; }
if [ "$(printf '%.2f' "$cost")" != "0.00" ]; then
  # A red "(202K⏱)" after the turn price: tokens this turn's cache misses rebuilt, by
  # Claude Code's likely cause: ⏱ TTL ran out, ⇄ model changed, ↻ anything else.
  miss_tag=""
  _lost=$((pc_missed - base_missed))
  if [ "$_lost" -gt 0 ]; then
    case "$pc_cause" in
      *ttl_expired*) _cause="⏱" ;;
      *model*)       _cause="⇄" ;;
      '')            _cause="" ;;
      *)             _cause="↻" ;;
    esac
    miss_tag="${RED}($(tokens "$_lost")${_cause})${RESET}"
  fi
  if [ "$idle" != 1 ]; then
    # Working: Claude Code's spinner flower blooms in place of the "$" (every glyph one
    # cell wide, so nothing shifts), its colour on the same frame, the "$" surfacing once
    # a cycle. Until the turn bills anything, four stars hold the figure's place, a shape
    # distinct from the flower so "no number yet" differs from "number on its way".
    case $((now % 9)) in
      0)   flower="·"; bloom=180 ;;
      1|7) flower="✢"; bloom=174 ;;
      2|6) flower="✳"; bloom=173 ;;
      3|5) flower="✻"; bloom=209 ;;
      8)   flower="$"; bloom=202 ;;
      *)   flower="✽"; bloom=202 ;;
    esac
    bloom="${ESC}[38;5;${bloom}m"
    if [ "$turn_billed" = 1 ]; then
      turn_disp=$(trunc1 "$turn_cost")
      turn_str="${bloom}${flower}${RESET}${turn_disp}${miss_tag}"
    else
      turn_disp=0
      turn_str="${bloom}★★★★${RESET}"
    fi
  else
    # Idle: the finished turn's price (the previous one until this turn bills) and how
    # long ago it ended. Near the cache's expiry the age says what stepping away costs:
    # "(-51m > 5m⇒+=203K)", blinking when the rebuild is big.
    [ "$turn_billed" = 1 ] && turn_disp=$(trunc1 "$turn_cost") || turn_disp=$(trunc1 "$prev_turn_cost")
    # Brace every variable that a non-ASCII glyph touches ("${_cmp}⇒"): in a UTF-8 locale
    # macOS's bash 3.2 reads the glyph's first byte as part of the name, so without the
    # braces the variable expands to nothing and leaves two stray bytes. test-statusline.sh
    # greps for the unbraced form.
    age=""
    if [ -n "$age_secs" ]; then
      if [ "$age_secs" -lt 60 ]; then age="-${age_secs}s"
      elif [ "$age_secs" -lt 3600 ]; then age="-$((age_secs / 60))m"
      else age=">1h"   # every cache is gone past an hour
      fi
      _cmp=""
      if [ "$age" != ">1h" ]; then
        [ "$phase" = expired ] && _cmp=" > $ttl" || _cmp=" <= $ttl"
      fi
      _hue=red; [ "$phase" = expiring ] && _hue=orange
      if [ "$phase" = none ]; then age=" $age"
      elif [ "$fc_tokens" -lt 500 ]; then age=" $age$_cmp"
      elif [ -n "$big_miss" ]; then
        age=" ($(pulse $_hue "$age")${_cmp}⇒+=$(pulse $_hue "$(tokens "$fc_tokens")"))"
      else
        age=" ($age${_cmp}⇒+=$(tokens "$fc_tokens"))"
      fi
    fi
    turn_str="\$${turn_disp}${miss_tag}${age}"
  fi
  # One decimal below $10, whole dollars above, unless that would drop below the turn
  # figure beside it (one turn being nearly the whole session).
  total_money=$(awk -v c="$cost" -v t="$turn_disp" 'BEGIN { d = int(c)
    if (c >= 10 && d >= t) printf "$%d", d; else printf "$%.1f", int(c * 10 + 1e-9) / 10 }')
  out="$out$sep$turn_str ⊂ $total_money"
  sep=" | "
fi

# --- Location: "folder@branch" on a coloured block ----------------------------------
# The REPO's name, not the directory's: in petclinic/backend it reads "petclinic", since
# half the repos have a "backend". A worktree names itself. Cached per Claude Code
# process ($PPID) because it only changes on cd; key first so paths with spaces survive.
_repo_file="$HOME/.claude/cwd/.repo-$PPID"
_repo_key=''; _repo_root=''
[ -r "$_repo_file" ] && { read -r _repo_key; read -r _repo_root; } < "$_repo_file" 2>/dev/null
if [ "$_repo_key" != "$cwd" ]; then
  _repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  { mkdir -p "$HOME/.claude/cwd" && printf '%s\n%s\n' "$cwd" "$_repo_root" > "$_repo_file"; } 2>/dev/null || :
fi
locpath=${_repo_root:-$cwd}
loc=${locpath%/}; loc=${loc##*/}; : "${loc:=/}"
# --show-current, since `rev-parse --abbrev-ref HEAD` fails on an unborn branch. Trunk
# is left out: the default state trains the eye to skip the field.
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
case "$branch" in ''|master|main) branch_sfx= ;; *) branch_sfx="@$branch" ;; esac

# The block's colour is hashed from the path: same folder, same colour, everywhere.
# Twenty background:foreground pairs, half inverted to widen the range of hues, in
# 256 colours since Terminal.app has no truecolor. On a light page each slot becomes a
# pastel of the same family. The raw checksum is cached, so palette edits apply at once.
if [ "$LIGHT_UI" = 1 ]; then
  FOLDER_CHIPS='153:16 147:16 219:16 218:16 157:16 158:16 229:16 222:16 117:16 181:16 223:16 194:16 189:16 224:16 187:16 159:16 217:16 186:16 183:16 250:16'
else
  FOLDER_CHIPS='25:231 61:231 91:231 126:231 28:231 30:231 100:231 130:231 19:231 88:231 223:16 194:16 189:16 224:16 230:16 195:16 217:16 186:16 183:16 252:16'
fi
_chip_file="$HOME/.claude/cwd/.chip-$PPID"
_chip_sum=''; _chip_key=''
[ -r "$_chip_file" ] && read -r _chip_sum _chip_key < "$_chip_file" 2>/dev/null
if [ "$_chip_key" != "$locpath" ]; then
  _chip_sum=$(printf '%s' "$locpath" | cksum 2>/dev/null | cut -d' ' -f1)
  case "$_chip_sum" in ''|*[!0-9]*) _chip_sum=0 ;; esac
  { mkdir -p "$HOME/.claude/cwd" && printf '%s %s\n' "$_chip_sum" "$locpath" > "$_chip_file"; } 2>/dev/null || :
fi
set -- $FOLDER_CHIPS
shift $((_chip_sum % $#))
# The branch stays outside the block: the block says which folder, not where HEAD is.
out="$out ${ESC}[48;5;${1%:*}m${ESC}[38;5;${1#*:}m${loc}${RESET}${branch_sfx}"

# --- Weekly quota: "+6=27% (F86%) / 1wd1h" --------------------------------------------
#   +6=    pace in percentage points off a straight line: positive is slack in hand,
#          negative is burning ahead of the week; nothing when on pace
#   27%    quota left this week
#   (F86%) the per-model cap (Fable's), only while that model is in use
#   1wd1h  WORKING time to the reset
if [ -n "$week" ]; then
  pct_left "$week"; paint_low "$_p" "$_p%"; week_seg=$_pl

  wchip=""
  case "$wscoped_label" in
    ''|-) ;;
    *)
      # Case-folded match against the untouched display name.
      mlc=$(printf '%s' "$model_name" | tr '[:upper:]' '[:lower:]')
      slc=$(printf '%s' "$wscoped_label" | tr '[:upper:]' '[:lower:]')
      case "$mlc:$wscoped" in
        *:|*:-|*:-1|*:*[!0-9.]*) ;;
        *"$slc"*:*)
          # A reading whose window has turned over is last week's budget.
          if [ -z "$wscoped_reset" ] || [ "$wscoped_reset" = 0 ] || [ "$wscoped_reset" -gt "$now" ] 2>/dev/null; then
            pct_left "$wscoped"
            paint_low "$_p" "$(printf '%.1s' "$wscoped_label" | tr '[:lower:]' '[:upper:]')$_p%"
            wchip=" ($_pl)"
          fi ;;
      esac ;;
  esac

  wdur=""
  if [ "${week_reset:-0}" -gt "$now" ] 2>/dev/null; then
    # Pace and time left both count WORKING time: weekends burn no quota, so calendar
    # time would call you behind all Friday and flatter you on Monday. The UTC offset is
    # read once; a DST shift inside the window costs an hour, noise against five days.
    off=$(date +%z | awk '{ s = (substr($0, 1, 1) == "-") ? -1 : 1
      print s * (substr($0, 2, 2) * 3600 + substr($0, 4, 2) * 60) }')
    # -> "<pace points> <time left>"
    read -r delta wdur <<EOF
$(awk -v u="$week" -v now="$now" -v r="$week_reset" -v off="$off" '
  # seconds of [a,b) on weekdays; 1970-01-01 was a Thursday, so dow = (day + 4) % 7
  function work(a, b,   s, d, dow, ds, x, y) {
    s = 0
    for (d = int((a + off) / 86400); d * 86400 - off < b; d++) {
      dow = (d + 4) % 7
      if (dow == 0 || dow == 6) continue
      ds = d * 86400 - off
      x = (a > ds) ? a : ds; y = (b < ds + 86400) ? b : ds + 86400
      if (y > x) s += y - x
    }
    return s
  }
  BEGIN {
    ws = r - 604800; if (now < ws) now = ws
    wt = work(ws, r); wl = work(now, r)
    e = (wt - wl) / wt * 100
    # "1wd1h": "wd" for working days; under a day "5h", then "45m".
    dd = int(wl / 86400); hh = int((wl % 86400) / 3600)
    left = (dd > 0) ? (hh > 0 ? sprintf("%dwd%dh", dd, hh) : sprintf("%dwd", dd)) \
         : (hh > 0) ? sprintf("%dh", hh) : sprintf("%dm", int(wl / 60))
    printf "%.0f %s\n", e - u, left
  }')
EOF
    case "$delta" in
      0|-0) ;;
      -*) [ "${delta#-}" -ge 10 ] && _c=$RED || _c=$ORANGE
          week_seg="${_c}${delta}${RESET}=$week_seg" ;;
      *)  week_seg="${GREEN}+${delta}${RESET}=$week_seg" ;;
    esac
  fi
  out="$out $week_seg$wchip${wdur:+ / $wdur}"
fi

[ -n "$DEBUG_LOG" ] && printf '%s OUT %s %s\n' "$now" "${session_id%%-*}" \
  "$(printf '%s' "$out" | sed 's/\x1b\[[0-9;]*m//g')" >> "$DEBUG_LOG" 2>/dev/null
echo "$out"
