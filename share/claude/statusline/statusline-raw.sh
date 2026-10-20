#!/bin/sh
# Claude Code status line, raw edition: shows only what Claude Code reports.
#   line 1: "Model effort | ctx used/size pct | cache state"
#   line 2: "$session duration | 5h used | 7d used | where"
#
# No transcript parsing, no state files, no network. The only arithmetic is unit
# formatting (tokens -> "194K", seconds -> "3m") and the countdown to a timestamp
# Claude Code gave us. Quotas are shown as "used", as reported, not "left".
# Every field used is documented at https://code.claude.com/docs/en/statusline

tokens() {
  if [ "$1" -ge 1000000 ]; then
    _t=$((($1 + 50000) / 100000)); echo "$((_t / 10)).$((_t % 10))M"
  else
    echo "$((($1 + 500) / 1000))K"
  fi
}
# span SECONDS -> "45s", "12m", "3h05"
span() {
  if [ "$1" -ge 86400 ]; then printf '%dd%dh' $(($1 / 86400)) $((($1 % 86400) / 3600))
  elif [ "$1" -ge 3600 ]; then printf '%dh%02d' $(($1 / 3600)) $((($1 % 3600) / 60))
  elif [ "$1" -ge 60 ]; then printf '%dm' $(($1 / 60))
  else printf '%ds' "$1"
  fi
}

input=$(cat)
# One jq for every field. `s` maps null/absent to "" without turning false into "".
eval "$(printf '%s' "$input" | jq -r '
def s: if . == null then "" else tostring end;
@sh "model=\(.model.display_name? | s | sub(" context\\)"; ")"))
effort=\(.effort.level? | s)
fast=\(.fast_mode? | s)
thinking=\(.thinking.enabled? | s)
used_tokens=\(.context_window.total_input_tokens? | s)
size=\(.context_window.context_window_size? | s)
used_pct=\(.context_window.used_percentage? | s)
warm=\(.prompt_cache.warm? | s)
observed=\(.prompt_cache.caching_observed? | s)
ttl=\(.prompt_cache.ttl? | s)
expires=\(.prompt_cache.expires_at? | s)
hit=\(.prompt_cache.hit_ratio? | s)
misses=\(.prompt_cache.misses? | s)
miss_tokens=\(.prompt_cache.miss_recache_tokens? | s)
miss_cause=\((.prompt_cache.last_miss_cause.causes? // []) | join(","))
recache=\(.prompt_cache.recache_tokens_if_cold? | s)
cost=\(.cost.total_cost_usd? | s)
dur_ms=\(.cost.total_duration_ms? | s)
added=\(.cost.total_lines_added? | s)
removed=\(.cost.total_lines_removed? | s)
five=\(.rate_limits.five_hour.used_percentage? | s)
five_reset=\(.rate_limits.five_hour.resets_at? | s)
week=\(.rate_limits.seven_day.used_percentage? | s)
week_reset=\(.rate_limits.seven_day.resets_at? | s)
spend_pct=\(.rate_limits.spend_limit.used_percentage? | s)
spend_usd=\(.rate_limits.spend_limit.used_usd? | s)
spend_max=\(.rate_limits.spend_limit.limit_usd? | s)
cwd=\(.workspace.current_dir? // .cwd? | s)
repo=\(.workspace.repo.name? | s)
wtree=\(.workspace.git_worktree? | s)
pr=\(.pr.number? | s)
pr_state=\(.pr.review_state? | s)
session=\(.session_name? | s)
agent=\(.agent.name? | s)
vim=\(.vim.mode? | s)"' 2>/dev/null)"
now=$(date +%s)

ESC=$(printf '\033'); RESET="${ESC}[0m"; RED="${ESC}[31m"; DIM="${ESC}[2m"

# --- Line 1: model, context, prompt cache --------------------------------------------
l1="${model:-Claude}${effort:+ $effort}"
[ "$fast" = true ] && l1="$l1 fast"
[ "$thinking" = false ] && l1="$l1 nothink"

# Exact tokens from the last response (input only, as used_percentage), not pct x size.
if [ -n "$used_tokens" ] && [ -n "$size" ]; then
  l1="$l1 | ctx $(tokens "$used_tokens")/$(tokens "$size")"
  [ -n "$used_pct" ] && l1="$l1 $(printf '%.0f' "$used_pct")%"
fi

if [ "$observed" = true ]; then
  c="cache $ttl"
  if [ "$warm" = true ] && [ -n "$expires" ]; then
    left=$((${expires%%.*} - now))
    [ "$left" -gt 0 ] && c="$c warm ${DIM}for${RESET} $(span "$left")" || c="$c warm"
  else
    c="${RED}cache $ttl cold${RESET}"
  fi
  [ -n "$hit" ] && c="$c, hit $(awk -v h="$hit" 'BEGIN { printf "%.0f", h * 100 }')%"
  [ -n "$recache" ] && c="$c, cold +$(tokens "${recache%%.*}")"
  if [ "${misses:-0}" -gt 0 ] 2>/dev/null; then
    c="$c, ${RED}${misses} miss${RESET}"
    [ -n "$miss_tokens" ] && c="$c ($(tokens "$miss_tokens")${miss_cause:+ $miss_cause})"
  fi
  l1="$l1 | $c"
fi

# --- Line 2: spend, quotas, place ------------------------------------------------------
l2=""
add() { l2="${l2:+$l2 | }$1"; }

[ -n "$cost" ] && {
  s="\$$(printf '%.2f' "$cost")"
  [ -n "$dur_ms" ] && s="$s in $(span $((${dur_ms%%.*} / 1000)))"
  { [ "${added:-0}" -gt 0 ] || [ "${removed:-0}" -gt 0 ]; } 2>/dev/null && s="$s +$added -$removed"
  add "$s"
}

# quota LABEL USED RESET_EPOCH -> "5h 12% (resets in 3h05)"
quota() {
  _q="$1 $(printf '%.0f' "$2")%"
  [ -n "$3" ] && [ "$(( ${3%%.*} - now ))" -gt 0 ] && _q="$_q (resets in $(span $((${3%%.*} - now))))"
  add "$_q"
}
[ -n "$five" ] && quota 5h "$five" "$five_reset"
[ -n "$week" ] && quota 7d "$week" "$week_reset"
if [ -n "$spend_usd" ] && [ -n "$spend_max" ]; then add "spend \$$spend_usd/\$$spend_max"
elif [ -n "$spend_pct" ]; then add "spend $(printf '%.0f' "$spend_pct")%"
fi

where="${repo:-${cwd##*/}}"
[ -n "$wtree" ] && where="$where [$wtree]"
[ -n "$pr" ] && where="$where PR#$pr${pr_state:+ $pr_state}"
[ -n "$agent" ] && where="$where agent:$agent"
[ -n "$vim" ] && where="$where $vim"
[ -n "$session" ] && where="$session: $where"
[ -n "$where" ] && add "$where"

printf '%s\n' "$l1"
[ -n "$l2" ] && printf '%s\n' "$l2"
