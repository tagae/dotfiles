#!/bin/sh
# shellcheck disable=SC3043  # `local` is not POSIX, but dash, bash and ash all have it
# shellcheck disable=SC2016  # the dollar amounts in the expectations are literal

# Regression tests for statusline-compact.sh: feed it sample JSON payloads (what Claude Code hands
# a status line on stdin) and assert on the rendered line. Colours are asserted on the raw
# escape codes, with "<208>text</>" standing for ESC[38;5;208m text ESC[0m.
#
# POSIX sh, like the script. Names are lowercase (uppercase is reserved for the environment),
# and functions keep their variables `local`, except the ones that set up the fixture on purpose.
# The script keeps one state file per session in $TMPDIR/claude (the sandbox allows writes
# there, not in /tmp; CLAUDE_STATUSLINE_STATE_DIR points it there), keyed by session_id
# (HOME is not involved); every session id here starts with "compact-test-", and cleanup removes them.
#
#   ./test-compact.sh

set -o errexit -o nounset

cd "$(dirname "$0")" || exit 2

script="$PWD/statusline-compact.sh"
self="$PWD/$(basename "$0")"

state_dir="${TMPDIR:-/tmp}/claude"
mkdir -p "$state_dir"
CLAUDE_STATUSLINE_STATE_DIR=$state_dir
export CLAUDE_STATUSLINE_STATE_DIR

cleanup() { rm -rf "$state_dir"/claude-statusline-compact-compact-test-*.txt 2>/dev/null; }

trap cleanup EXIT INT TERM
cleanup

passed=0
failed=0
esc=$(printf '\033')

report_pass() { passed=$((passed + 1)); printf 'ok    %s\n' "$1"; }
report_fail() { failed=$((failed + 1)); printf 'FAIL  %s\n      %s\n' "$1" "$2"; }

# strip_colour TEXT -> TEXT without its colour escapes.
strip_colour() { printf '%s' "$1" | sed "s/${esc}\[[0-9;]*m//g"; }

# assert_contains LABEL LINE NEEDLE, and its opposite: on the line without its colours.
assert_contains() {
  case $(strip_colour "$2") in
    *"$3"*) report_pass "$1" ;;
    *) report_fail "$1" "expected to find: $3
      got:              $(strip_colour "$2")" ;;
  esac
}
assert_not_contains() {
  case $(strip_colour "$2") in
    *"$3"*) report_fail "$1" "expected NOT to find: $3
      got:                  $(strip_colour "$2")" ;;
    *) report_pass "$1" ;;
  esac
}
# assert_equals LABEL LINE EXPECTED: the whole line, without its colours.
assert_equals() {
  if [ "$(strip_colour "$2")" = "$3" ]; then
    report_pass "$1"
  else
    report_fail "$1" "expected: $3
      got:      $(strip_colour "$2")"
  fi
}
# assert_coloured LABEL LINE NEEDLE: the needle with its colours, "<N>" for ESC[38;5;Nm and
# "</>" for ESC[0m, so a colour is checked on exactly the text it paints.
assert_coloured() {
  local expected
  expected=$(printf '%s' "$3" | sed "s/<\\/>/${esc}[0m/g; s/<\\([0-9;]*\\)>/${esc}[38;5;\\1m/g")
  case $2 in
    *"$expected"*) report_pass "$1" ;;
    *) report_fail "$1" "expected to find: $3
      got:              $(printf '%s' "$2" | sed "s/${esc}\\[38;5;\\([0-9]*\\)m/<\\1>/g; s/${esc}\\[0m/<\\/>/g")" ;;
  esac
}

# The payload every case starts from; a case overrides what it is about. "null" is how Claude
# Code spells a value it has not got yet; *_json variables hold JSON as it is written.
# *_resets_in and *_expires_in are seconds from the moment of the render, and sit 30 s past a
# minute boundary so that a second or two of drift between the test and the script still
# reads the same ("2h30", not "2h29").
reset_payload() {
  prompt_id=p1; model="Sonnet 5.5"; effort_json='"high"'
  context_used=10; context_size=1000000
  input_tokens=234000; cache_write_tokens=1900; output_tokens=842
  cost_usd=3.62; wall_ms=7200000; api_ms=900000
  five_used=32; five_resets_in=9030; week_used=56; week_resets_in=302430
  has_cache=1; cache_ttl_label=1h; cache_expires_in=3030; miss_total=0
  session_name_json='"Sha tweak"'
  pinned_now=   # the epoch the offsets count from; empty means the moment of each render
}
# The script tells a new response from an old one by the payload changing, and the reset
# times here move with the clock: a case that renders twice and cares about the state pins it.
pin_now() { pinned_now=$(date +%s); }

# render_line SESSION: the payload built from the variables above, through the script.
render_line() {
  local now expires_at cache_json
  now=${pinned_now:-$(date +%s)}
  expires_at=null
  [ "$cache_expires_in" = null ] || expires_at=$((now + cache_expires_in))
  cache_json=
  if [ -n "$has_cache" ]; then
    cache_json=$(printf ',"prompt_cache":{"ttl":"%s","expires_at":%s,"miss_recache_tokens":%s,"last_miss_cause":{"causes":["ttl_expired_5m"]}}' \
      "$cache_ttl_label" "$expires_at" "$miss_total")
  fi
  printf '{"session_id":"compact-test-%s","prompt_id":"%s","model":{"display_name":"%s"},"effort":{"level":%s},"context_window":{"used_percentage":%s,"context_window_size":%s,"total_input_tokens":%s,"current_usage":{"cache_creation_input_tokens":%s,"output_tokens":%s}},"cost":{"total_cost_usd":%s,"total_duration_ms":%s,"total_api_duration_ms":%s},"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%s},"seven_day":{"used_percentage":%s,"resets_at":%s}}%s,"session_name":%s}' \
    "$1-$$" "$prompt_id" "$model" "$effort_json" "$context_used" "$context_size" "$input_tokens" \
    "$cache_write_tokens" "$output_tokens" "$cost_usd" "$wall_ms" "$api_ms" \
    "$five_used" "$((now + five_resets_in))" "$week_used" "$((now + week_resets_in))" \
    "$cache_json" "$session_name_json" | sh "$script" || printf '[the script exited with status %s]' "$?"
}

state_file_of() { echo "$state_dir/claude-statusline-compact-compact-test-$1-$$.txt"; }
# age_state_file SESSION SECONDS: pretend this session's last response was that long ago.
age_state_file() {
  awk -v t=$(($(date +%s) - $2)) 'NR == 6 { print t; next } { print }' "$(state_file_of "$1")" \
    > "$(state_file_of "$1").tmp" && mv "$(state_file_of "$1").tmp" "$(state_file_of "$1")"
}

# --- The script itself -------------------------------------------------------------------
# Claude Code runs it directly: without the executable bit the status line goes blank.
if [ -x "$script" ]; then report_pass "script: executable"; else report_fail "script: executable" "chmod +x $script"; fi
if sh -n "$script" 2>/dev/null; then report_pass "script: valid syntax"; else report_fail "script: valid syntax" "sh -n failed"; fi
for file in "$script" "$self"; do
  if grep -q '^set -o errexit -o nounset$' "$file"; then
    report_pass "$(basename "$file"): runs with errexit and nounset"
  else
    report_fail "$(basename "$file"): runs with errexit and nounset" "no 'set -o errexit -o nounset' line"
  fi
done
assert_equals "script: without jq it says so" "$(PATH=/nonexistent /bin/sh "$script" </dev/null)" "statusline: jq is required"
assert_equals "script: malformed JSON still gives a line" "$(printf 'not json' | sh "$script")" "Claude"
assert_equals "script: an empty payload is just a name" "$(printf '{}' | sh "$script")" "Claude"

# --- Everything at once: the segments and their order ---------------------------------------
reset_payload
out=$(render_line order)
assert_equals "line: the full example, in order" "$out" \
  'S5.5h ↑234K/1M (+1.9K, ◕50m) ↓842 $3.62 ⚙15m/2h00 ⧖ 32%↗ ↻2h30 ▦ 56% ↻3d12h'
assert_not_contains "line: no session name (Claude shows it elsewhere)" "$out" "Sha tweak"
assert_coloured "model: the initial is white, the version light grey, the effort plain" "$out" "<255>S</><249>5.5</>h ↑"
assert_coloured "cost: the session total is light grey" "$out" "<249>\$3.62</> ⚙"
assert_not_contains "line: no dividers" "$out" "|"
for label in "in:" "out:" "up:" "api:" "ttl:" "5h:" "7d:"; do
  assert_not_contains "line: no $label label, icons instead" "$out" "$label"
done

# --- Model and effort ----------------------------------------------------------------------
# The family by its initial, the version and the effort level after it with nothing between.
for pair in 'low:l' 'medium:m' 'high:h' 'xhigh:xh' 'max:x'; do
  reset_payload; effort_json="\"${pair%%:*}\""
  assert_contains "effort: ${pair%%:*} reads ${pair#*:}" "$(render_line effort)" "S5.5${pair#*:} "
done
reset_payload; effort_json='"ultra"'
assert_contains "effort: a level we do not know is shown as it is" "$(render_line effort)" "S5.5ultra "
reset_payload; effort_json=null; model="Haiku 5.5"
assert_contains "effort: a model without one has no suffix" "$(render_line effort)" "H5.5 ↑"
for pair in 'Sonnet 5.5:S5.5' 'Opus 5.5:O5.5' 'Haiku 5.5:H5.5' 'Fable 5.1:F5.1'; do
  reset_payload; model=${pair%%:*}
  assert_contains "model: ${pair%%:*} reads ${pair#*:}" "$(render_line model)" "${pair#*:}h "
done
reset_payload; model="Mystery 9"
assert_contains "model: a family we do not know is shown as it is" "$(render_line model)" "Mystery 9h "

# --- Tokens ----------------------------------------------------------------------------------
reset_payload
out=$(render_line tokens)
assert_contains     "tokens: input with the window size"        "$out" "↑234K/1M"
assert_contains     "tokens: output"                            "$out" "↓842"
assert_contains     "tokens: growth is the cache write"         "$out" "(+1.9K, ◕50m)"
assert_not_contains "tokens: no cache read"                     "$out" "r232K"
assert_not_contains "tokens: no fresh input"                    "$out" "f2"
assert_not_contains "tokens: no cold-start figure"              "$out" "→"
# Counts: one decimal, none when it would be 0.
for row in '999:999' '1000:1K' '1049:1K' '1050:1.1K' '9950:10K' '10000:10K' '15499:15K' '999499:999K' '999500:1M' '999999:1M' '1000000:1M' '1500000:1.5M'; do
  reset_payload; output_tokens=${row%%:*}
  assert_contains "shorten: ${row%%:*} reads ${row#*:}" "$(render_line shorten)" "↓${row#*:} "
done
reset_payload; context_size=1500000
assert_contains "tokens: a 1.5M window" "$(render_line tokens)" "↑234K/1.5M"
reset_payload; context_size=200000
assert_contains     "tokens: a 200K window"                     "$(render_line tokens)" "↑234K/200K"
reset_payload; cache_write_tokens=null
assert_contains     "bracket: only the ttl when nothing was written" "$(render_line tokens)" "↑234K/1M (◕50m) ↓842"
reset_payload; has_cache=
assert_contains     "bracket: only the growth without a cache"       "$(render_line tokens)" "↑234K/1M (+1.9K) ↓842"
reset_payload; cache_write_tokens=null; has_cache=
assert_not_contains "bracket: none when there is nothing to show"    "$(render_line tokens)" "("

# --- Fields of the wrong type are left out, and the rest of the line stays ---------------------
reset_payload; input_tokens='"many"'
out=$(render_line types)
assert_not_contains "types: a string where tokens belong leaves out the input" "$out" "/1M"
assert_contains     "types: ... and the rest of the line stays"          "$out" "↓842"
reset_payload; output_tokens=-5
assert_not_contains "types: a negative count is left out"    "$(render_line types)" "↓842"
reset_payload; cost_usd='"free"'
assert_not_contains "types: a string cost is left out"       "$(render_line types)" '$'
reset_payload; five_used='"half"'
assert_not_contains "types: a string quota is left out"      "$(render_line types)" "⧖"
reset_payload; input_tokens=234000.7
assert_contains     "types: a fractional count is rounded down" "$(render_line types)" "↑234K/1M"

# --- Context colour: light grey, yellow from 60, orange from 80, red from 90 -------------------
for pair in '59:249' '60:220' '79:220' '80:208' '89:208' '90:196'; do
  reset_payload; context_used=${pair%%:*}
  out=$(render_line context)
  assert_coloured "context ${pair%%:*}%: colour ${pair#*:}" "$out" "↑<${pair#*:}>234K</>/1M"
done
reset_payload; context_used=null
assert_coloured "context: unknown share is light grey" "$(render_line context)" "↑<249>234K</>/1M"

# --- Cost: the turn, then the session ---------------------------------------------------------
reset_payload; cost_usd=1.00
out=$(render_line cost1)
assert_contains     "cost: first render shows the session only" "$out" ' $1.00 '
assert_not_contains "cost: no turn yet"                         "$out" '⊂'
cost_usd=1.10; out=$(render_line cost1)
assert_contains     "cost: the turn so far, then the session"   "$out" '$0.10 ⊂ $1.10'
prompt_id=p2; out=$(render_line cost1)
assert_contains     "cost: a new prompt keeps the last turn until it bills" "$out" '$0.10 ⊂ $1.10'
cost_usd=1.30; out=$(render_line cost1)
assert_contains     "cost: the new turn once it bills"          "$out" '$0.20 ⊂ $1.30'
prompt_id=p3; cost_usd=0.05; out=$(render_line cost1)
assert_contains     "cost: /clear resets the total, no negative turn" "$out" ' $0.05 '
assert_not_contains "cost: /clear shows no turn"                "$out" '⊂'
reset_payload; cost_usd=0.125
out=$(render_line cost2); prompt_id=p2; out=$(render_line cost2)
assert_contains     "cost: a half cent rounds the same way on both sides" "$out" '$0.13'
assert_not_contains "cost: the turn never exceeds the session" "$out" '$0.13 ⊂ $0.12'
reset_payload; cost_usd=null
assert_not_contains "cost: absent when not reported"            "$(render_line cost3)" '$'

# --- Cache miss: per turn, never plain, coloured by the share of the context re-cached ------------
# check_miss LABEL MISS_TOKENS COLOUR TEXT, with 100K input tokens: 11K, 50K and 80K re-cached
# are 11%, 50% and 80% of the context.
check_miss() {
  local out
  reset_payload; input_tokens=100000; miss_total=0
  render_line "miss-$1" >/dev/null
  miss_total=$2; out=$(render_line "miss-$1")
  assert_coloured "miss: $1" "$out" "<$3>miss: $4 ttl_expired_5m</>"
}
check_miss 11pct 11000 220 11K
check_miss 49pct 49000 220 49K
check_miss 50pct 50000 208 50K
check_miss 79pct 79000 208 79K
check_miss 80pct 80000 196 80K
check_miss 150pct 150000 196 150K
reset_payload; input_tokens=100000; render_line miss-pos >/dev/null; miss_total=11000
assert_contains "miss: inside the bracket, after the ttl" "$(render_line miss-pos)" "(+1.9K, ◕50m, miss: 11K ttl_expired_5m) ↓842"
reset_payload; input_tokens=100000; render_line miss-gone >/dev/null; miss_total=11000; render_line miss-gone >/dev/null
prompt_id=p2; out=$(render_line miss-gone)
assert_not_contains "miss: gone when the next prompt starts" "$out" "miss:"
reset_payload; miss_total=11000; out=$(render_line miss-none)
assert_not_contains "miss: the session's earlier total is not a miss" "$out" "miss:"
reset_payload; input_tokens=null; render_line miss-unknown >/dev/null; miss_total=11000; out=$(render_line miss-unknown)
assert_coloured "miss: yellow when the context size is unknown" "$out" "<220>miss: 11K ttl_expired_5m</>"

# --- Prompt cache countdown (ttl) -----------------------------------------------------------------------
reset_payload
out=$(render_line ttl)
assert_contains "ttl: time left" "$out" "◕50m"
# Plain at half the lifetime or more, then four steps (3600 s lifetime): light yellow below
# 50% left, yellow below 38%, light orange below 26%, orange below 15%.
reset_payload; cache_expires_in=1830
case $(render_line ttl) in
  *"◕30m"*) report_pass "ttl: plain at half the lifetime" ;;
  *) report_fail "ttl: plain at half the lifetime" "got: $(render_line ttl | cat -v)" ;;
esac
# Each row: seconds left, colour, text, icon.
for row in '1650:229:27m:◔' '1230:220:20m:◔' '810:215:13m:◔' '330:208:5m:○'; do
  reset_payload; cache_expires_in=${row%%:*}; rest=${row#*:}; colour_of=${rest%%:*}; rest=${rest#*:}
  assert_coloured "ttl: $colour_of at ${row%%:*} s left" "$(render_line ttl)" "${rest#*:}<$colour_of>${rest%%:*}</>"
done
# Either side of every threshold: share left 14/16 (15%), 25/27 (26%), 37/39 (38%), 49/51 (50%).
for row in '520:208:8m:◔' '590:215:9m:◔' '915:215:15m:◔' '990:220:16m:◔' '1350:220:22m:◔' '1420:229:23m:◔' '1780:229:29m:◔'; do
  reset_payload; cache_expires_in=${row%%:*}; rest=${row#*:}; colour_of=${rest%%:*}; rest=${rest#*:}
  assert_coloured "ttl: $colour_of with ${row%%:*} s left" "$(render_line ttl)" "${rest#*:}<$colour_of>${rest%%:*}</>"
done
# The pie, by the share of the lifetime left (3600 s): ● from 88%, ◕ from 50%, ◔ from 13%, ○ below.
for row in '3600:●' '3168:●' '3164:◕' '1800:◕' '1796:◔' '468:◔' '464:○' '0:○'; do
  reset_payload; cache_expires_in=${row%%:*}
  assert_contains "ttl icon: ${row#*:} with ${row%%:*} s left" "$(render_line ttl)" "(+1.9K, ${row#*:}"
done
reset_payload; cache_expires_in=1850
case $(render_line ttl) in
  *"◕30m"*) report_pass "ttl: plain just above half the lifetime" ;;
  *) report_fail "ttl: plain just above half the lifetime" "got: $(render_line ttl | cat -v)" ;;
esac
reset_payload; cache_expires_in=-150
out=$(render_line ttl)
assert_coloured "ttl: past the expiry is orange, like the last step" "$out" "<208>-2m</>"
assert_contains "ttl: past the expiry, by how much" "$out" "○-2m"
reset_payload; cache_expires_in=-7230
assert_contains "ttl: hours past" "$(render_line ttl)" "○-2h00"
# Never red, anywhere on the way down or past the expiry.
for secs_left in 30 150 400 700 1000 1400 1800 2400 -150; do
  reset_payload; cache_expires_in=$secs_left
  case $(render_line ttl) in
    *"${esc}[38;5;196m"*) report_fail "ttl: never red, $secs_left s" "a red span at $secs_left s" ;;
    *) report_pass "ttl: never red, $secs_left s" ;;
  esac
done
reset_payload; cache_expires_in=null
assert_contains "ttl: no expiry in the payload" "$(render_line ttl)" "○expired"
assert_coloured "ttl: expired is the same orange as the overdue time" "$(render_line ttl)" "<208>expired</>"

# The lifetime label is read, not looked up: any "<number><s|m|h|d>" gives the steps.
reset_payload; cache_ttl_label=30m; cache_expires_in=450       # 25% of 1800 s
assert_coloured "ttl label: 30m is read" "$(render_line ttl)" "◔<215>7m</>"
reset_payload; cache_ttl_label=2h; cache_expires_in=2430       # 33% of 7200 s
assert_coloured "ttl label: 2h is read" "$(render_line ttl)" "◔<220>40m</>"
for label in forever 0m 05m 2h30m 3h05 2d4h 1x ''; do
  reset_payload; cache_ttl_label=$label; cache_expires_in=450
  case $(render_line ttl) in
    *"●7m"*) report_pass "ttl label: '$label' is not understood, the countdown stays plain" ;;
    *) report_fail "ttl label: '$label' is not understood, the countdown stays plain" "got: $(render_line ttl | cat -v)" ;;
  esac
done

# --- Durations ------------------------------------------------------------------------------------------
reset_payload; wall_ms=45000; api_ms=2000   # durations are the payload's own: exact
assert_contains "durations: seconds" "$(render_line dur)" "⚙2s/45s"
reset_payload; wall_ms=3300000
assert_contains "durations: minutes" "$(render_line dur)" "/55m"
reset_payload; wall_ms=11100000
assert_contains "durations: hours" "$(render_line dur)" "/3h05"

# --- Quotas: label, colour, pace arrow -----------------------------------------------------------
# Half the 5h window left (9000 s): 20% used is far ahead, 40% ahead, 50% on pace, 60%
# behind, 75% far behind.
for row in '20:<114>↑</>' '40:<114>↗</>' '60:<220>↘</>' '75:<196>↓</>'; do
  reset_payload; five_used=${row%%:*}
  assert_coloured "5h pace: ${row%%:*}% used" "$(render_line pace5)" "%</>${row#*:}"
done
reset_payload; five_used=50
assert_not_contains "5h pace: on pace has no arrow" "$(render_line pace5)" "50%↑"
assert_contains "5h pace: on pace" "$(render_line pace5)" "⧖ 50% ↻2h30"
# The same for the week, half of it (302400 s) left.
for row in '20:<114>↑</>' '40:<114>↗</>' '60:<220>↘</>' '75:<196>↓</>'; do
  reset_payload; week_used=${row%%:*}
  assert_coloured "7d pace: ${row%%:*}% used" "$(render_line pace7)" "%</>${row#*:}"
done
reset_payload; week_used=50
assert_contains "7d pace: on pace, calendar time left" "$(render_line pace7)" "▦ 50% ↻3d12h"

# Colour of the figure itself: light grey below 70, yellow from 70, orange from 80, red from 90.
for pair in '69:249' '70:220' '79:220' '80:208' '90:196'; do
  reset_payload; five_used=${pair%%:*}; five_resets_in=17000
  out=$(render_line quota)
  assert_coloured "5h colour ${pair%%:*}%: ${pair#*:}" "$out" "<${pair#*:}>${pair%%:*}%</>"
done
reset_payload; five_resets_in=9030
assert_coloured "5h: the reset time is light grey" "$(render_line quota)" "↻<249>2h30</>"
reset_payload; five_used=null
assert_not_contains "quota: absent when not reported" "$(render_line quota)" "⧖"
reset_payload; five_resets_in=-30
out=$(render_line quota)
assert_contains     "quota: a window that has ended has no countdown" "$out" "⧖ 32%?"
assert_not_contains "quota: no arrow for a window that has ended"     "$out" "↑32"

# --- Staleness: no response for 15 minutes, on both quotas --------------------------------------------
reset_payload; pin_now
render_line stale >/dev/null
age_state_file stale 1200
out=$(render_line stale)
assert_contains     "stale: 5h figure marked"            "$out" "⧖ 32%? ↻"
assert_contains     "stale: 7d figure marked"            "$out" "▦ 56%? ↻"
assert_coloured     "stale: grey"                        "$out" "<245>32%?</>"
assert_not_contains "stale: the arrow goes"              "$out" "↑32"
age_state_file stale 600
assert_not_contains "stale: not before 15 minutes"       "$(render_line stale)" "%?"
age_state_file stale 1200
cost_usd=3.70; out=$(render_line stale)
assert_not_contains "stale: a new response makes it fresh" "$out" "%?"
age_state_file stale 1200
# shellcheck disable=SC2030,SC2031  # set in a subshell on purpose, so it cannot leak
out=$(export CLAUDE_QUOTA_STALE_SECS=1800; render_line stale)
assert_not_contains "stale: the threshold is configurable" "$out" "%?"
# shellcheck disable=SC2030,SC2031  # set in a subshell on purpose, so it cannot leak
out=$(export CLAUDE_QUOTA_STALE_SECS=600; render_line stale)
assert_contains     "stale: a lower threshold marks it"  "$out" "%?"
age_state_file stale 1200
# shellcheck disable=SC2030,SC2031  # set in a subshell on purpose, so it cannot leak
out=$(export CLAUDE_QUOTA_STALE_SECS=soon; render_line stale)
assert_contains     "stale: a threshold that is not a number falls back to the default" "$out" "%?"

# --- State file ------------------------------------------------------------------------------------------
reset_payload; pin_now
printf 'p9\n500000\n0\n0\n' > "$(state_file_of migrate)"   # the older four-line format
prompt_id=p9; cost_usd=0.55
out=$(render_line migrate)
assert_contains "state: an older four-line file is read" "$out" '$0.05 ⊂ $0.55'
if [ "$(wc -l < "$(state_file_of migrate)" | tr -d ' ')" = 6 ]; then
  report_pass "state: rewritten with six lines"
else
  report_fail "state: rewritten with six lines" "$(cat "$(state_file_of migrate)")"
fi
before=$(cat "$(state_file_of migrate)")
render_line migrate >/dev/null
if [ "$(cat "$(state_file_of migrate)")" = "$before" ]; then
  report_pass "state: untouched while nothing changes"
else
  report_fail "state: untouched while nothing changes" "rewritten"
fi
printf 'garbage\nx\ny\nz\n' > "$(state_file_of corrupt)"
reset_payload; assert_contains "state: a corrupt file does not break the line" "$(render_line corrupt)" "S5.5"

# A state file that cannot be written (here, a directory in its place) must not stop the line.
reset_payload
mkdir "$(state_file_of unwritable)"
assert_contains "state: an unwritable file does not stop the line" "$(render_line unwritable 2>&1)" "S5.5"

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
