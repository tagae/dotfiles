#!/bin/sh
# Minimal regression harness for statusline-fancy.sh: feeds sample
# JSON payloads (what Claude Code hands the script on stdin) and asserts
# substrings in the rendered line, so the rendering is checked by an assertion
# instead of by eye. Not a general test framework -- just enough to keep the
# segments from silently regressing.
#
# Runs in a throwaway $HOME so it never touches the real quota/cwd state
# under ~/.claude, and cleans up its /tmp state files (those are keyed by
# session_id and hardcoded to /tmp inside the script itself, HOME override or
# not -- see the "why /tmp and not $HOME" note in the script for cost/turn
# caching).
#
#   ./test-statusline.sh
cd "$(dirname "$0")" || exit 2
SCRIPT="$PWD/statusline-fancy.sh"

TMP=$(mktemp -d)
cleanup() {
  rm -rf "$TMP"
  rm -f /tmp/claude-statusline-*-statusline-test-*.txt 2>/dev/null
  rm -f /tmp/claude-turn-statusline-test-*.state 2>/dev/null
}
trap cleanup EXIT INT TERM
export HOME="$TMP"
mkdir -p "$HOME/.claude"

pass=0
fail=0

# strip_ansi + assert_contains "<label>" "<haystack>" "<needle>"
assert_contains() {
  label=$1; haystack=$2; needle=$3
  plain=$(printf '%s' "$haystack" | sed 's/\x1b\[[0-9;]*m//g')
  case "$plain" in
    *"$needle"*) pass=$((pass + 1)); printf 'ok    %s\n' "$label" ;;
    *)
      fail=$((fail + 1))
      printf 'FAIL  %s\n      expected to find: %s\n      got:              %s\n' \
        "$label" "$needle" "$plain"
      ;;
  esac
}

assert_not_contains() {
  label=$1; haystack=$2; needle=$3
  plain=$(printf '%s' "$haystack" | sed 's/\x1b\[[0-9;]*m//g')
  case "$plain" in
    *"$needle"*)
      fail=$((fail + 1))
      printf 'FAIL  %s\n      expected NOT to find: %s\n      got:                  %s\n' \
        "$label" "$needle" "$plain"
      ;;
    *) pass=$((pass + 1)); printf 'ok    %s\n' "$label" ;;
  esac
}

# Expected wall clock for an epoch, on whichever `date` this machine has: BSD/macOS
# spells it `-r EPOCH`, GNU/Linux `-d @EPOCH` (see fmt_epoch in the script;
# test-date-fallback.sh is what tests the script's own fallback).
clock_of() { date -r "$1" "$2" 2>/dev/null || date -d "@$1" "$2"; }

now=$(date +%s)
reset=$((now + 3 * 3600 + 23 * 60))   # 3h23m from now

# --- Case 1: normal 5h quota ----------------------------------------------
payload=$(cat <<JSON
{"session_id":"statusline-test-normal","model":{"display_name":"Claude Opus"},
 "context_window":{},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset}}}
JSON
)
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains    "normal: quota-left percentage"     "$out" "60%"
assert_contains    "normal: window countdown"           "$out" "3h2"

week_reset=$((now + 2 * 86400 + 47 * 60))

# --- Case 2: a probe reading outranks a frozen session payload --------------
# The plan-switch bug of 2026-09-11 (Max 5x -> 20x): an idle terminal keeps
# re-publishing the payload it was handed before the allowance grew, and by
# value that old, higher figure wins the merge on every render. quota-probe.sh
# writes the account's real number with source=probe, and quota-state.sh must
# refuse to let a NON-fresh session reading displace it. Needs the real
# quota-state.sh under this throwaway HOME; quota-probe.sh is deliberately
# absent, so the render never fires a network request from a test.
STATE="$PWD/hooks/quota-state.sh"
mkdir -p "$HOME/.claude/hooks"
ln -s "$STATE" "$HOME/.claude/hooks/quota-state.sh"
session="statusline-test-weekly-probe"
rm -f "/tmp/claude-statusline-rl-$session.txt"
payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Claude Opus"},
 "context_window":{},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset},
                "seven_day":{"used_percentage":94,"resets_at":$week_reset}}}
JSON
)
# First render: nothing stored and a payload never seen -> fresh, and 94 lands.
# This is the pre-upgrade state every terminal was in.
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains "probe: the frozen payload paints the old plan's number first" "$out" "6% /"
# The probe arrives with the account's real figure.
"$STATE" set -1 0 9 "$week_reset" >/dev/null
# Same bytes again -> non-fresh -> the measurement holds, whatever the cache says.
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains "probe: the measured 9% used replaces the frozen 94%" "$out" "91% /"
assert_not_contains "probe: the old plan's number is gone" "$out" "6% /"

# Protection lasts two probe intervals (the probe runs every one). Past that the
# probe reading is as old as anything else and value order resumes -- the
# deliberate fallback when the probe keeps failing.
jq '.seven_day.measured_at -= 601' "$HOME/.claude/quota.json" > "$HOME/.claude/quota.json.new" \
  && mv "$HOME/.claude/quota.json.new" "$HOME/.claude/quota.json"
out=$(printf '%s' "$payload" | env -u CLAUDE_QUOTA_PROBE_SECS -u CLAUDE_WEEKLY_QUOTA_PROBE_SECS sh "$SCRIPT")
assert_contains "probe: an aged-out probe reading yields to value order again" "$out" "6% /"
rm -f "$HOME/.claude/hooks/quota-state.sh" "$HOME/.claude/quota.json"

# --- Case 3: the per-model weekly cap rides beside the account weekly -------
# An account can hold two weekly budgets: the account-wide one and a per-model
# cap with its own allowance (Fable's, since 2026-09). quota-probe.sh used to
# write whichever was TIGHTER into `seven_day`, so on 2026-09-21 the bar read
# "86% left" while /usage said 92% -- Fable's budget wearing the account's
# label, with nothing on screen to tell them apart. The account figure is the
# weekly number now; the scoped cap is a chip carrying the model's initial.
STATE="$PWD/hooks/quota-state.sh"
mkdir -p "$HOME/.claude/hooks"
ln -s "$STATE" "$HOME/.claude/hooks/quota-state.sh"
session="statusline-test-weekly-scoped"
rm -f "/tmp/claude-statusline-rl-$session.txt"
payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Claude Opus"},
 "context_window":{},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset},
                "seven_day":{"used_percentage":8,"resets_at":$week_reset}}}
JSON
)
"$STATE" set -1 0 8 "$week_reset" 14 "$week_reset" Fable >/dev/null
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains "scoped cap: the weekly figure is the ACCOUNT's"    "$out" "92%"
# Fable's cap is not an Opus session's business: no chip there.
assert_not_contains "scoped cap: another model's cap stays off the bar" "$out" "(F86%)"
fable_payload=$(printf '%s' "$payload" | sed 's/"Claude Opus"/"Claude Fable"/')
out=$(printf '%s' "$fable_payload" | sh "$SCRIPT")
assert_contains "scoped cap: the model's own budget rides beside it" "$out" "(F86%)"

# A reading whose weekly window has already turned over is last week's budget.
"$STATE" set -1 0 8 "$week_reset" 14 "$((now - 60))" Fable >/dev/null
out=$(printf '%s' "$fable_payload" | sh "$SCRIPT")
assert_not_contains "scoped cap: a reading past its reset is dropped" "$out" "(F"

# An account with no per-model cap shows exactly the cell it always had.
rm -f "$HOME/.claude/quota.json"
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_not_contains "scoped cap: no cap, no chip" "$out" "(F"
rm -f "$HOME/.claude/hooks/quota-state.sh" "$HOME/.claude/quota.json"

# --- Case: subagents in flight ----------------------------------------------
# Builds a session directory shaped like the one Claude Code writes -- a parent
# transcript plus <sid>/subagents/agent-<id>.{meta.json,jsonl} -- and checks the
# three judgements the chip has to make: who is still running, what each one is
# running on, and how the groups collapse.
session="statusline-test-subagents"
proj="$HOME/.claude/projects/test"
sub="$proj/$session/subagents"
mkdir -p "$sub"
tp="$proj/$session.jsonl"

# Every line carries a UTC stamp: an agent counts as stopped only when its
# newest stop-marker is at least as recent as the last line it wrote itself.
# Agents write at 10:00; markers land from 10:05 on; a wake writes later still.
T0='"timestamp":"2026-09-20T10:00:00.000Z",'
# A line the agent itself writes when something wakes it, stamped at 10:MM.
wake() {
  printf '{"type":"assistant","timestamp":"2026-09-20T10:%s:00.000Z","agentId":"%s","message":{"role":"assistant"}}\n' "$2" "$1" >> "$sub/agent-$1.jsonl"
}

# id / model / effort ("-" = none, as Haiku writes it) / requested-alias
mk_agent() {
  printf '{"agentType":"general-purpose","description":"t","toolUseId":"toolu_%s","spawnDepth":1,"model":"%s"}' \
    "$1" "$4" > "$sub/agent-$1.meta.json"
  eff=",\"effort\":\"$3\""
  [ "$3" = "-" ] && eff=""
  printf '{"type":"user",%s"isSidechain":true,"agentId":"%s","message":{"role":"user"}}\n{"type":"assistant",%s"agentId":"%s"%s,"message":{"role":"assistant","model":"%s"}}\n' \
    "$T0" "$1" "$T0" "$1" "$eff" "$2" > "$sub/agent-$1.jsonl"
}
mk_agent A claude-opus-5              high   opus
mk_agent B claude-opus-5              high   opus
mk_agent C claude-sonnet-5            medium sonnet
mk_agent D claude-opus-5              high   opus
mk_agent E claude-haiku-4-5-20251001  -      haiku
mk_agent F claude-fable-5-1           high   fable
mk_agent G claude-opus-5              high   opus

{
  # The spawn itself: tool_use blocks carry the id as "id", never as
  # "tool_use_id", so none of these may read as a finished agent.
  printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_A","name":"Task"},{"type":"tool_use","id":"toolu_D","name":"Task"}]}}\n'
  # D returned; E was launched async in the SAME user turn. The launch receipt
  # must not be mistaken for D's result, nor D's result for E's.
  printf '{"type":"user","timestamp":"2026-09-20T10:05:00.000Z","message":{"content":[{"tool_use_id":"toolu_D","type":"tool_result","content":"the report"},{"tool_use_id":"toolu_E","type":"tool_result","content":[{"type":"text","text":"Async agent launched successfully. agentId: E"}]}]}}\n'
  # F was launched async and has since notified that it stopped.
  printf '{"type":"user","message":{"content":[{"tool_use_id":"toolu_F","type":"tool_result","content":[{"type":"text","text":"Async agent launched successfully. agentId: F"}]}]}}\n'
  printf '{"type":"user","timestamp":"2026-09-20T10:05:00.000Z","message":{"content":"<task-notification>\\n<task-id>F</task-id>\\n<tool-use-id>toolu_F</tool-use-id>\\n<status>completed</status>\\n</task-notification>"}}\n'
} > "$tp"

# G never got a marker but has been silent for hours: a corpse, not a worker.
touch -t 202001010000 "$sub/agent-G.jsonl"

payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Opus 5 (1M context)"},
 "effort":{"level":"high"},"transcript_path":"$tp",
 "context_window":{"used_percentage":6,"context_window_size":1000000},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset}}}
JSON
)
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains     "subagents: groups by model+effort, biggest first" "$out" "+{O5h×2,H4.5,S5m}"
assert_not_contains "subagents: no effort letter is invented for Haiku" "$out" "H4.5h"
assert_contains     "subagents: chip hangs off the model segment"      "$out" "60K +{"
assert_not_contains "subagents: a returned Task is gone"               "$out" "×3"
assert_not_contains "subagents: a notified async agent is gone"        "$out" "F5.1"
assert_not_contains "subagents: a silent corpse is not counted"        "$out" "×4"

# Second render, same state: the per-agent facts now come from the cache file
# rather than from re-reading seven agent transcripts. Same answer either way.
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains "subagents: cached second render is identical" "$out" "+{O5h×2,H4.5,S5m}"

# --- Case 4: a done-marker that has scrolled out of the scanned tail ---------
# Only the last $CLAUDE_SUB_TAIL bytes of the parent transcript are read, and a
# busy session writes past its own markers. Once F's notification falls outside
# that window the scan can no longer see that F ever stopped -- unless the first
# render wrote the id down. This is the bug that had a finished async agent
# sitting in the chip for a quarter of an hour (10 Sep 2026).
session="statusline-test-scrolled"
sub="$proj/$session/subagents"
mkdir -p "$sub"
tp="$proj/$session.jsonl"
mk_agent F claude-fable-5-1 high fable
{
  printf '{"type":"user","message":{"content":[{"tool_use_id":"toolu_F","type":"tool_result","content":[{"type":"text","text":"Async agent launched successfully. agentId: F"}]}]}}\n'
  printf '{"type":"user","timestamp":"2026-09-20T10:05:00.000Z","message":{"content":"<task-notification>\\n<task-id>F</task-id>\\n<tool-use-id>toolu_F</tool-use-id>\\n<status>completed</status>\\n</task-notification>"}}\n'
  # Everything after the marker: enough of it to push the marker out of a small tail.
  i=0
  while [ "$i" -lt 200 ]; do
    printf '{"type":"assistant","message":{"content":"padding padding padding padding padding padding padding padding"}}\n'
    i=$((i + 1))
  done
} > "$tp"

payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Opus 5 (1M context)"},
 "effort":{"level":"high"},"transcript_path":"$tp",
 "context_window":{"used_percentage":6,"context_window_size":1000000},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset}}}
JSON
)
# First render: the marker is still inside a generous tail, so F is seen to stop.
out=$(printf '%s' "$payload" | CLAUDE_SUB_TAIL=2000000 sh "$SCRIPT")
assert_not_contains "scrolled: marker inside the tail retires the agent" "$out" "F5.1"
# Second render, tail now too small to reach the marker. Without the remembered
# id, F comes back from the dead and the chip lies until the mtime floor.
out=$(printf '%s' "$payload" | CLAUDE_SUB_TAIL=4000 sh "$SCRIPT")
assert_not_contains "scrolled: marker outside the tail stays retired" "$out" "F5.1"
assert_not_contains "scrolled: no chip left at all"                   "$out" "+{"

# --- Case 5: an async agent resumed with SendMessage ------------------------
# The first stop earns the agent a marker, and the marker is remembered. A
# SendMessage addressed to its id restarts it under the same toolUseId, so the
# remembered marker alone would hide it for the rest of the session while it
# works (13 Sep 2026: chip showed one agent, the native list two). A resume seen
# AFTER the last marker means live again; the next stop retires it once more.
session="statusline-test-resumed"
sub="$proj/$session/subagents"
mkdir -p "$sub"
tp="$proj/$session.jsonl"
mk_agent F claude-fable-5-1 high fable
{
  printf '{"type":"user","message":{"content":[{"tool_use_id":"toolu_F","type":"tool_result","content":[{"type":"text","text":"Async agent launched successfully. agentId: F"}]}]}}\n'
  printf '{"type":"user","timestamp":"2026-09-20T10:05:00.000Z","message":{"content":"<task-notification>\\n<task-id>F</task-id>\\n<tool-use-id>toolu_F</tool-use-id>\\n<status>completed</status>\\n</task-notification>"}}\n'
} > "$tp"
payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Opus 5 (1M context)"},
 "effort":{"level":"high"},"transcript_path":"$tp",
 "context_window":{"used_percentage":6,"context_window_size":1000000},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset}}}
JSON
)
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_not_contains "resumed: the first stop retires the agent" "$out" "F5.1"
# Enough traffic to push that marker out of a small tail, then the resume. The
# remembered id says done; the resume inside the window must win over it.
i=0
while [ "$i" -lt 200 ]; do
  printf '{"type":"assistant","message":{"content":"padding padding padding padding padding padding padding padding"}}\n' >> "$tp"
  i=$((i + 1))
done
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_S1","name":"SendMessage","input":{"to":"F","summary":"one more thing","message":"carry on"}}]}}\n' >> "$tp"
wake F 10
out=$(printf '%s' "$payload" | CLAUDE_SUB_TAIL=4000 sh "$SCRIPT")
assert_contains "resumed: a SendMessage after the marker brings it back" "$out" "+{F5.1h}"
# The second stop: same toolUseId, new notification, later than the resume.
printf '{"type":"user","timestamp":"2026-09-20T10:20:00.000Z","message":{"content":"<task-notification>\\n<task-id>F</task-id>\\n<tool-use-id>toolu_F</tool-use-id>\\n<status>completed</status>\\n</task-notification>"}}\n' >> "$tp"
# A message to something that is not one of our agents changes nothing.
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_S2","name":"SendMessage","input":{"to":"reviewer","message":"ping"}}]}}\n' >> "$tp"
out=$(printf '%s' "$payload" | CLAUDE_SUB_TAIL=4000 sh "$SCRIPT")
assert_not_contains "resumed: the second stop retires it again"        "$out" "F5.1"
assert_not_contains "resumed: a message to a stranger revives nothing" "$out" "+{"

# --- Case 6: a slash-command forked into the background ---------------------
# /code-review run in the background is an agent like any other -- its own
# transcript, its own line in the native list as @code-review-2 -- but its
# meta.json carries a "name" and no "toolUseId" whatsoever. A scan keyed on that
# one field dropped it before it was ever counted, and the chip stayed blank
# through an hour-long review (15 Sep 2026). Such an agent is keyed on its own
# agentId, retired on the <task-id> of its notification, and resumable by name.
session="statusline-test-forked-skill"
sub="$proj/$session/subagents"
mkdir -p "$sub"
tp="$proj/$session.jsonl"

# id / @name / model / effort. No toolUseId and no model alias: exactly the
# shape Claude Code writes for a forked skill.
mk_forked() {
  printf '{"agentType":"general-purpose","description":"/code-review main","name":"%s","spawnDepth":1,"requestShape":"background","requestNonInteractive":true}' \
    "$2" > "$sub/agent-$1.meta.json"
  printf '{"type":"user",%s"isSidechain":true,"agentId":"%s","message":{"role":"user"}}\n{"type":"assistant",%s"agentId":"%s","effort":"%s","message":{"role":"assistant","model":"%s"}}\n' \
    "$T0" "$1" "$T0" "$1" "$4" "$3" > "$sub/agent-$1.jsonl"
}
mk_forked P code-review   claude-opus-5   high
mk_forked Q code-review-2 claude-sonnet-5 medium
{
  # The launch receipt. It names the agent under "agentId", and its own
  # tool_use_id belongs to the Skill call, not to the agent -- so it can never
  # read as that agent stopping.
  printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_P","content":"Skill launched (forked execution, running in the background).\\n\\nRunning in the background as @code-review"}]},"toolUseResult":{"status":"forked","background":true,"agentId":"P"}}\n'
  printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_Q","content":"Skill launched (forked execution, running in the background).\\n\\nRunning in the background as @code-review-2"}]},"toolUseResult":{"status":"forked","background":true,"agentId":"Q"}}\n'
} > "$tp"

payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Opus 5 (1M context)"},
 "effort":{"level":"high"},"transcript_path":"$tp",
 "context_window":{"used_percentage":6,"context_window_size":1000000},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset}}}
JSON
)
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains "forked skill: an agent with no toolUseId is still counted" "$out" "+{O5h,S5m}"

# P stops. Its notification carries the launch tool-use-id, which is NOT the key
# here, and the agent id, which is -- so this retires it only via <task-id>.
printf '{"type":"user","timestamp":"2026-09-20T10:05:00.000Z","message":{"content":"<task-notification>\\n<task-id>P</task-id>\\n<tool-use-id>toolu_P</tool-use-id>\\n<status>killed</status>\\n</task-notification>"}}\n' >> "$tp"
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_not_contains "forked skill: its notification retires it by task-id" "$out" "O5h"
assert_contains     "forked skill: the one still working stays"            "$out" "+{S5m}"

# Resumed the way one of these is usually resumed: by @name, not by id.
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_S3","name":"SendMessage","input":{"to":"code-review","message":"carry on"}}]}}\n' >> "$tp"
wake P 10
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_contains "forked skill: a SendMessage to its @name brings it back" "$out" "+{O5h,S5m}"

# A session that never spawned anything renders no chip at all.
session="statusline-test-no-subagents"
tp="$proj/$session.jsonl"
printf '{"type":"assistant","message":{"content":[]}}\n' > "$tp"
payload=$(cat <<JSON
{"session_id":"$session","model":{"display_name":"Opus 5 (1M context)"},
 "effort":{"level":"high"},"transcript_path":"$tp",
 "context_window":{"used_percentage":6,"context_window_size":1000000},
 "rate_limits":{"five_hour":{"used_percentage":40,"resets_at":$reset}}}
JSON
)
out=$(printf '%s' "$payload" | sh "$SCRIPT")
assert_not_contains "no subagents: no chip, no placeholder" "$out" "+{"
assert_not_contains "no subagents: placeholder is resolved" "$out" "@@SUB@@"

# --- Case: the prompt cache, as Claude Code reports it ----------------------
# Every cache figure on the bar is Claude Code's own `prompt_cache`: the miss tag is
# the growth of `miss_recache_tokens` since the turn's `prompt_id` appeared, its
# glyph the `last_miss_cause`; the idle forecast is `recache_tokens_if_cold`, its
# colour `expires_at` against the `ttl`.
# usage_line <requestId> <in> <read> <write> <w1h> <w5m> <out> <stop> <HH:MM>
usage_line() {
  printf '{"type":"assistant","uuid":"a-%s","requestId":"%s","timestamp":"2026-09-20T%s:00.000Z","message":{"role":"assistant","stop_reason":"%s","content":[],"usage":{"input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation_input_tokens":%s,"cache_creation":{"ephemeral_1h_input_tokens":%s,"ephemeral_5m_input_tokens":%s},"output_tokens":%s}}}\n' \
    "$1" "$1" "$9" "$8" "$2" "$3" "$4" "$5" "$6" "$7"
}
prompt_line() {
  printf '{"type":"user","uuid":"%s","timestamp":"2026-09-20T%s:00.000Z","message":{"role":"user","content":"%s"}}\n' "$1" "$2" "$1"
}
# Two renders of one turn, as Claude Code does: the turn price is the delta of
# total_cost_usd between them.
render_twice() {  # 1=session 2=model-id 3=display 4=cost-before 5=cost-after 6=total_input_tokens
  rm -f /tmp/claude-statusline-*-"$1".txt 2>/dev/null
  _p='{"session_id":"%s","model":{"id":"%s","display_name":"%s"},"effort":{"level":"xhigh"},"transcript_path":"%s","context_window":{"used_percentage":23,"context_window_size":1000000,"total_input_tokens":%s},"cost":{"total_cost_usd":%s}}'
  printf "$_p" "$1" "$2" "$3" "$proj/$1.jsonl" "$6" "$4" | sh "$SCRIPT" >/dev/null
  printf "$_p" "$1" "$2" "$3" "$proj/$1.jsonl" "$6" "$5" | sh "$SCRIPT"
}
# render_pc <session> <prompt_id> <cost> <prompt_cache JSON>: one render of an idle
# Opus 5.5 session whose last reply landed $PC_AGE seconds ago.
iso_of() { date -u -r "$1" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%S; }
render_pc() {
  printf '{"type":"assistant","requestId":"r1","timestamp":"%s.000Z","message":{"stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":5}}}\n' \
    "$(iso_of $((now - ${PC_AGE:-60})))" > "$proj/$1.jsonl"
  printf '{"session_id":"%s","prompt_id":"%s","model":{"id":"claude-opus-5-5[1m]","display_name":"Opus 5.5 (1M context)"},"transcript_path":"%s","context_window":{"used_percentage":23,"context_window_size":1000000},"cost":{"total_cost_usd":%s},"prompt_cache":%s}' \
    "$1" "$2" "$proj/$1.jsonl" "$3" "$4" | sh "$SCRIPT"
}
pc() {  # pc <ttl> <expires_at> <miss_recache_tokens> <recache_tokens_if_cold> [causes JSON]
  printf '{"warm":true,"ttl":"%s","expires_at":%s,"miss_recache_tokens":%s,"recache_tokens_if_cold":%s,"last_miss_cause":%s}' \
    "$1" "$2" "$3" "$4" "${5:-null}"
}

# A turn whose first request found the 1h cache gone: Claude Code counted a
# 202,329-token miss and blamed the TTL.
session="statusline-test-miss-ttl"
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 12.000 "$(pc 1h $((now + 3500)) 0 227000)" >/dev/null
out=$(render_pc "$session" p1 13.632 "$(pc 1h $((now + 3500)) 202329 227000 '{"causes":["ttl_expired_1h"]}')")
assert_contains     "miss, TTL: turn price is Claude Code's own delta" "$out" '$1.6('
assert_contains     "miss, TTL: sized by Claude Code's miss tokens"   "$out" '(202K⏱)'
assert_not_contains "miss, TTL: a warm cache forecasts nothing"       "$out" '⇒'

# The miss belongs to the turn it happened in: the next prompt starts clean.
out=$(render_pc "$session" p2 13.632 "$(pc 1h $((now + 3500)) 202329 227000 '{"causes":["ttl_expired_1h"]}')")
assert_not_contains "miss, TTL: gone once a new prompt starts" "$out" '⏱'

# The glyph is the cause Claude Code names.
session="statusline-test-miss-switch"
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 12.000 "$(pc 1h $((now + 3500)) 1000 227000)" >/dev/null
out=$(render_pc "$session" p1 12.300 "$(pc 1h $((now + 3500)) 203000 227000 '{"causes":["model_changed"]}')")
assert_contains     "model switch: the rebuild is tagged with the switch glyph" "$out" '(202K⇄)'
assert_not_contains "model switch: not the stopwatch" "$out" '⏱'

session="statusline-test-miss-tools"
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 5.000 "$(pc 1h $((now + 3500)) 0 150000)" >/dev/null
out=$(render_pc "$session" p1 5.400 "$(pc 1h $((now + 3500)) 150000 150000 '{"causes":["tools_changed"],"tools_added":2}')")
assert_contains "tools changed: tagged as a plain rebuild" "$out" '(150K↻)'

session="statusline-test-miss-unknown"
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 5.000 "$(pc 1h $((now + 3500)) 0 150000)" >/dev/null
out=$(render_pc "$session" p1 5.400 "$(pc 1h $((now + 3500)) 50000 150000)")
assert_contains "unknown cause: sized, no glyph" "$out" '(50K)'

# A healthy turn carries no tag at all.
session="statusline-test-cache-hit"
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 5.000 "$(pc 1h $((now + 3500)) 0 155000)" >/dev/null
out=$(render_pc "$session" p1 5.200 "$(pc 1h $((now + 3500)) 0 155000)")
assert_not_contains "cache hit: no miss tag" "$out" 'K⏱'
assert_not_contains "cache hit: no forecast while warm" "$out" '⇒'

# Idle near the end of the TTL: the clock turns orange and sizes the rebuild.
session="statusline-test-expiring"
rm -f /tmp/claude-statusline-*-"$session".txt
out=$(PC_AGE=3000 render_pc "$session" p1 5.000 "$(pc 1h $((now + 500)) 0 203000)")
assert_contains "expiring: forecast is Claude Code's recache figure" "$out" '(-50m <= 1h⇒+=203K)'

# Expired. `expires_at` counts from the request's START, so a cache can be gone
# although the last reply is younger than the TTL.
session="statusline-test-expired"
rm -f /tmp/claude-statusline-*-"$session".txt
out=$(PC_AGE=280 render_pc "$session" p1 5.000 "$(pc 5m $((now - 5)) 0 90000)")
assert_contains "expired: judged by expires_at, not by the reply's age" "$out" '(-4m > 5m⇒+=90K)'

# The forecast's "⇒" must survive a UTF-8 locale. There macOS's bash 3.2 reads the
# glyph's first byte as part of a variable name, so an unbraced "$_cmp⇒" expands to
# nothing and leaves two stray bytes (shown as "��"). The harness runs in whatever
# locale it was started in, usually C, where that never happens: pin one, and also
# lint for the pattern, since not every machine has a UTF-8 locale installed.
_hits=$(LC_ALL=C grep -nE '\$[A-Za-z_][A-Za-z0-9_]*[^ -~]' "$SCRIPT")
assert_contains "no unbraced variable touches a multibyte glyph" "${_hits:-none}" none
for _loc in en_US.UTF-8 C.UTF-8; do
  locale -a 2>/dev/null | grep -qx "$_loc" && break
  _loc=""
done
if [ -n "$_loc" ]; then
  session="statusline-test-utf8-locale"
  rm -f /tmp/claude-statusline-*-"$session".txt
  out=$(LC_ALL=$_loc PC_AGE=3000 render_pc "$session" p1 5.000 "$(pc 1h $((now + 500)) 0 203000)")
  assert_contains "UTF-8 locale ($_loc): forecast intact" "$out" '(-50m <= 1h⇒+=203K)'
  printf '%s' "$out" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 && _r=ok || _r=bad
  assert_contains "UTF-8 locale ($_loc): output is valid UTF-8" "$_r" ok
else
  echo "skip  UTF-8 locale: none installed (the lint above still ran)"
fi

# No `prompt_cache` (older Claude Code, or caching off): no forecast, no tag.
session="statusline-test-no-pc"
rm -f /tmp/claude-statusline-*-"$session".txt
out=$(PC_AGE=4000 render_pc "$session" p1 5.000 null)
assert_not_contains "no prompt_cache: no forecast" "$out" '⇒'
assert_not_contains "no prompt_cache: no tag"      "$out" 'K⏱'

# --- Case: the placeholder before the turn's first cost ----------------------
# Working (the prompt is the last line, nothing answered yet) and the session
# total has not moved: exactly four stars hold the slot -- as wide as the
# "✻0.5" they stand in for, so the total does not move when the figure lands;
# never one flower, never the flower repeated to pad it.
session="statusline-test-placeholder"
{
  prompt_line u0 09:00
  usage_line r0 2 50000 1000 1000 0 300 end_turn 09:01
  prompt_line u1 09:05
} > "$proj/$session.jsonl"
out=$(render_twice "$session" "claude-opus-5-5[1m]" "Opus 5.5 (1M context)" 3.000 3.000 51002)
assert_contains     "placeholder: four stars before the turn has a cost" "$out" '★★★★ ⊂ $3.0'
assert_not_contains "placeholder: exactly four" "$out" '★★★★★'
for _g in '·' '✢' '✳' '✻' '✽'; do
  assert_not_contains "placeholder: no lone flower ($_g)" "$out" " $_g ⊂"
done
# Once the first cost lands, the figure replaces the stars.
out=$(render_twice "$session" "claude-opus-5-5[1m]" "Opus 5.5 (1M context)" 3.000 3.500 51002)
assert_not_contains "placeholder: gone once a figure exists" "$out" '★'
assert_contains     "placeholder: the live figure takes its place" "$out" '0.5 ⊂ $3.5'

# --- Case: a tiny cost change still counts as billed ---------------------------
# Why the turn delta is computed with bc and must not be "simplified" to awk.
# total_cost_usd is a running sum and the turn price is the difference between two
# readings of it. awk subtracts doubles, and printing the result fixed-point rounds
# 0.30000000000000004 - 0.3 (5.6e-17) to 0.00000000: a real change in the total then
# reads as "nothing billed yet" and the bar keeps its four stars. bc subtracts the
# decimal strings exactly and sees it. Claude Code bills in far larger steps; this
# is the smallest change that tells the two apart.
session="statusline-test-tiny-cost"
rm -f "/tmp/claude-statusline-heur-$session.txt"
_p='{"session_id":"%s","model":{"display_name":"Claude Opus"},"context_window":{},"cost":{"total_cost_usd":%s}}'
printf "$_p" "$session" 0.3 | sh "$SCRIPT" >/dev/null
out=$(printf "$_p" "$session" 0.30000000000000004 | sh "$SCRIPT")
assert_contains     "tiny cost change: counted as billed, shown as a figure" "$out" '0.0 ⊂ $0.3'
assert_not_contains "tiny cost change: not mistaken for nothing billed yet" "$out" '★'

# --- Context colour is a percentage of the window ------------------------------
# The token count turns orange at 70% and red at 90%, whatever the window size
# or model family: Sonnet at 1M used to go red at 30% of the room (flat >300K).
# ctx_colour <model id> <display name> <window> <percent> -> the escape that
# precedes the "<N>K" token count
ctx_colour() {
  printf '{"session_id":"statusline-test-ctxcolour","model":{"id":"%s","display_name":"%s"},"context_window":{"used_percentage":%s,"context_window_size":%s,"total_input_tokens":%s},"cost":{"total_cost_usd":1}}' \
    "$1" "$2" "$4" "$3" "$(($3 / 100 * $4))" | sh "$SCRIPT" | sed -n 's/.*\(\x1b\[[0-9;]*m\)[0-9]*K\x1b\[0m.*/\1/p'
}
ESC=$(printf '\033')
BLUE="${ESC}[38;5;111m"; ORANGE="${ESC}[38;5;208m"; RED="${ESC}[31m"
expect_colour() {  # 1=label 2=expected escape 3..=ctx_colour args
  _label=$1; _want=$2; shift 2
  [ "$(ctx_colour "$@")" = "$_want" ] && _r=ok || _r=bad
  assert_contains "$_label" "$_r" ok
}
for _m in 'claude-sonnet-5-5[1m]|Sonnet 5.5 (1M context)' 'claude-opus-5-5[1m]|Opus 5.5 (1M context)'; do
  _id=${_m%%|*}; _name=${_m#*|}
  expect_colour "ctx colour, $_name 1M: 45% is blue, not red" "$BLUE"   "$_id" "$_name" 1000000 45
  expect_colour "ctx colour, $_name 1M: 69% is still blue"    "$BLUE"   "$_id" "$_name" 1000000 69
  expect_colour "ctx colour, $_name 1M: 70% is orange"        "$ORANGE" "$_id" "$_name" 1000000 70
  expect_colour "ctx colour, $_name 1M: 89% is still orange"  "$ORANGE" "$_id" "$_name" 1000000 89
  expect_colour "ctx colour, $_name 1M: 90% is red"           "$RED"    "$_id" "$_name" 1000000 90
done
# A smaller window is judged by the same percentages, and its "• N%" agrees.
expect_colour "ctx colour, Sonnet 200K: 69% is blue"   "$BLUE"   claude-sonnet-5-5 "Sonnet 5.5" 200000 69
expect_colour "ctx colour, Sonnet 200K: 70% is orange" "$ORANGE" claude-sonnet-5-5 "Sonnet 5.5" 200000 70
expect_colour "ctx colour, Sonnet 200K: 90% is red"    "$RED"    claude-sonnet-5-5 "Sonnet 5.5" 200000 90
out=$(printf '{"session_id":"statusline-test-ctxcolour","model":{"id":"claude-sonnet-5-5","display_name":"Sonnet 5.5"},"context_window":{"used_percentage":70,"context_window_size":200000,"total_input_tokens":140000},"cost":{"total_cost_usd":1}}' | sh "$SCRIPT")
case "$out" in *"${ORANGE}70%"*) _r=ok ;; *) _r=bad ;; esac
assert_contains "ctx colour, Sonnet 200K: the percentage turns orange with the count" "$_r" ok
rm -f /tmp/claude-*statusline-test-ctxcolour* 2>/dev/null

# --- The "auto" theme follows the terminal background ---------------------------
# A status line cannot ask the terminal, so $COLORFGBG ("fg;bg") stands in: a white
# or bright background means light. The context count shows the palette: blue 111
# on dark, 25 on light.
printf '{"theme":"auto"}' > "$HOME/.claude/settings.json"
theme_blue() {  # COLORFGBG value -> the escape before the token count
  printf '{"session_id":"statusline-test-theme","model":{"display_name":"Sonnet 5.5"},"context_window":{"used_percentage":10,"context_window_size":200000},"cost":{"total_cost_usd":1}}' \
    | COLORFGBG="$1" sh "$SCRIPT" | sed -n 's/.*\(\x1b\[[0-9;]*m\)[0-9]*K\x1b\[0m.*/\1/p'
}
[ "$(theme_blue '0;15')" = "${ESC}[38;5;25m" ] && _r=ok || _r=bad
assert_contains "auto theme: a bright background is light" "$_r" ok
[ "$(theme_blue '15;0')" = "$BLUE" ] && _r=ok || _r=bad
assert_contains "auto theme: a black background is dark" "$_r" ok
if ! command -v defaults >/dev/null 2>&1; then
  [ "$(theme_blue '')" = "$BLUE" ] && _r=ok || _r=bad
  assert_contains "auto theme: nothing to go by is dark" "$_r" ok
fi
# Without $COLORFGBG, macOS's appearance decides: `defaults read -g
# AppleInterfaceStyle` fails in light mode and prints "Dark" in dark mode.
mkdir -p "$TMP/light-mac" "$TMP/dark-mac"
printf '#!/bin/sh\nexit 1\n' > "$TMP/light-mac/defaults"
printf '#!/bin/sh\necho Dark\n' > "$TMP/dark-mac/defaults"
chmod +x "$TMP/light-mac/defaults" "$TMP/dark-mac/defaults"
[ "$(PATH="$TMP/light-mac:$PATH" theme_blue '')" = "${ESC}[38;5;25m" ] && _r=ok || _r=bad
assert_contains "auto theme: macOS in light mode is light" "$_r" ok
[ "$(PATH="$TMP/dark-mac:$PATH" theme_blue '')" = "$BLUE" ] && _r=ok || _r=bad
assert_contains "auto theme: macOS in dark mode is dark" "$_r" ok
[ "$(PATH="$TMP/light-mac:$PATH" theme_blue '15;0')" = "$BLUE" ] && _r=ok || _r=bad
assert_contains "auto theme: \$COLORFGBG outranks the macOS appearance" "$_r" ok
[ "$(CLAUDE_STATUSLINE_LIGHT=0 theme_blue '0;15')" = "$BLUE" ] && _r=ok || _r=bad
assert_contains "auto theme: CLAUDE_STATUSLINE_LIGHT overrides" "$_r" ok
rm -f "$HOME/.claude/settings.json" /tmp/claude-*statusline-test-theme* 2>/dev/null

# --- Idle age from the transcript ---------------------------------------------
# The "-Nm" clock counts from the last assistant message's timestamp, which the
# cached jq program turns into an epoch (fractional seconds and all).
tp="$TMP/statusline-test-age.jsonl"
printf '{"type":"user","uuid":"u1","message":{"content":"hello"}}\n' > "$tp"
printf '{"type":"assistant","requestId":"r1","timestamp":"%s.123Z","message":{"stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":5}}}\n' \
  "$(iso_of $((now - 7 * 60 - 30)))" >> "$tp"
out=$(printf '{"session_id":"statusline-test-age","model":{"display_name":"Claude Opus"},"context_window":{},"cost":{"total_cost_usd":0.5},"transcript_path":"%s"}' "$tp" \
  | sh "$SCRIPT")
assert_contains "idle age: counted from the last reply's timestamp" "$out" "-7m"

# --- Model, effort and context window ---------------------------------------------
# One render, no transcript. sl <session> <model display> <effort|""> <context JSON body>
sl() {
  rm -f /tmp/claude-statusline-*-"$1".txt 2>/dev/null
  _e=""; [ -n "$3" ] && _e=",\"effort\":{\"level\":\"$3\"}"
  printf '{"session_id":"%s","model":{"display_name":"%s"}%s,"context_window":{%s},"cost":{"total_cost_usd":1}}' \
    "$1" "$2" "$_e" "$4" | sh "$SCRIPT"
}
for _e in 'low|l' 'medium|m' 'high|h' 'xhigh|xh' 'max|max' 'turbo|turbo'; do
  out=$(sl statusline-test-effort "Opus 5.5" "${_e%%|*}" '')
  assert_contains "effort: ${_e%%|*} is glued on as \"${_e#*|}\"" "$out" "Opus 5.5${_e#*|} "
done
out=$(sl statusline-test-effort "Opus 5.5" "" '')
assert_contains "effort: none, no suffix" "$out" "Opus 5.5 "
# The display name's "(1M context)" is dropped even before there is a context figure.
out=$(sl statusline-test-1m-name "Opus 5.5 (1M context)" high '')
assert_contains     "1M name: the size label leaves the model name" "$out" "Opus 5.5h "
assert_not_contains "1M name: no stray parenthesis"                 "$out" "("
# The 1M display is decided by the window, never by the model family.
out=$(sl statusline-test-1m-sonnet "Sonnet 5.5" high '"used_percentage":45,"context_window_size":1000000')
assert_contains     "1M window: any family shows a bare count" "$out" "Sonnet 5.5h 450K "
assert_not_contains "1M window: no denominator"                "$out" "/1M"
out=$(sl statusline-test-200k "Opus 5.5" high '"used_percentage":40,"context_window_size":200000')
assert_contains "200K window: used, size and percentage" "$out" "Opus 5.5h 80K/200K • 40%"
case "$out" in *"• 40%"*) _r=ok ;; *) _r=bad ;; esac
assert_contains "200K window: the percentage is uncoloured below 70%" "$_r" ok

# --- Five-hour quota: burn arrow, staleness, chip ground ---------------------------
# five <session> <used%> <seconds to reset> [theme JSON]. Offsets carry 30 s of slack
# so a second ticking over between test and script cannot change the minute.
five() {
  rm -f "$HOME/.claude/quota.json" /tmp/claude-statusline-*-"$1".txt
  [ -n "${4:-}" ] && printf '%s' "$4" > "$HOME/.claude/settings.json"
  printf '{"session_id":"%s","model":{"display_name":"Claude Opus"},"context_window":{},"rate_limits":{"five_hour":{"used_percentage":%s,"resets_at":%s}}}' \
    "$1" "$2" "$((now + $3 + 30))" | sh "$SCRIPT"
  rm -f "$HOME/.claude/settings.json"
}
# Half the window left (9000 of 18000 s): the arrow compares quota left with that half.
for _c in '10|↑90%' '40|↗60%' '50|50%' '62|↘38%' '80|↓20%'; do
  out=$(five statusline-test-burn "${_c%%|*}" 9000)
  assert_contains "burn arrow: ${_c%%|*}% used halfway reads ${_c#*|}" "$out" "${_c#*|} / 2h30"
done
out=$(five statusline-test-burn 50 9000)
for _g in '↑' '↗' '↘' '↓'; do
  assert_not_contains "burn arrow: on pace shows no $_g" "$out" "$_g"
done
out=$(five statusline-test-burn 40 2700)
assert_contains "countdown: under an hour reads in minutes" "$out" "% / 45m"
# Ground colour by quota left, dark and light.
for _c in '40|60' '90|94' '97|88'; do
  out=$(five statusline-test-ground "${_c%%|*}" 9000)
  case "$out" in *"${ESC}[48;5;${_c#*|}m"*) _r=ok ;; *) _r=bad ;; esac
  assert_contains "chip ground: ${_c%%|*}% used is colour ${_c#*|}" "$_r" ok
done
for _c in '40|189' '90|223' '97|217'; do
  out=$(five statusline-test-ground "${_c%%|*}" 9000 '{"theme":"light"}')
  case "$out" in *"${ESC}[48;5;${_c#*|}m"*) _r=ok ;; *) _r=bad ;; esac
  assert_contains "chip ground, light: ${_c%%|*}% used is colour ${_c#*|}" "$_r" ok
done
# A reading nobody has re-confirmed for over 15 minutes turns into a grey "?". Needs
# the real merge: quota-state.sh records when a reading was last seen changing.
session=statusline-test-stale
ln -s "$PWD/hooks/quota-state.sh" "$HOME/.claude/hooks/quota-state.sh"
five "$session" 40 9000 >/dev/null
jq --argjson m "$((now - 2000))" '.five_hour.measured_at = $m' "$HOME/.claude/quota.json" > "$TMP/q.json"
mv "$TMP/q.json" "$HOME/.claude/quota.json"
out=$(printf '{"session_id":"%s","model":{"display_name":"Claude Opus"},"context_window":{},"rate_limits":{"five_hour":{"used_percentage":40,"resets_at":%s}}}' \
  "$session" "$((now + 9030))" | sh "$SCRIPT")
rm -f "$HOME/.claude/hooks/quota-state.sh" "$HOME/.claude/quota.json"
assert_contains     "stale 5h: marked with a question mark" "$out" "60%? / 2h30"
assert_not_contains "stale 5h: no confident arrow"          "$out" "↗"

# A quota-park marker from the retired gate is ignored.
session=statusline-test-old-park
mkdir -p "$HOME/.claude/quota-park"
printf '%s seven_day' "$((now + 3000))" > "$HOME/.claude/quota-park/$session"
out=$(five "$session" 98 9000)
assert_not_contains "retired park marker: no sleep glyph" "$out" "💤"
rm -rf "$HOME/.claude/quota-park"

# --- Separators and spend --------------------------------------------------------
# Without a 5h block the spend is fenced off by a pipe; the block's edge does it otherwise.
out=$(sl statusline-test-sep "Claude Opus" "" '"used_percentage":10,"context_window_size":1000000')
assert_contains "separator: a pipe when there is no 5h block" "$out" "100K | \$"
out=$(printf '{"session_id":"statusline-test-sep2","model":{"display_name":"Claude Opus"},"context_window":{},"cost":{"total_cost_usd":1},"rate_limits":{"five_hour":{"used_percentage":40,"resets_at":%s}}}' \
  "$((now + 9000))" | sh "$SCRIPT")
assert_not_contains "separator: no pipe beside the 5h block" "$out" "| \$"
# No transcript: the turn state is unknown, so the figure shows without an age.
assert_contains     "no transcript: the turn's figure, no stars" "$out" " \$0.0 ⊂ \$1.0"
assert_not_contains "no transcript: no placeholder stars"         "$out" "★"
# Totals: one decimal below $10, whole dollars from $10, unless whole dollars would
# fall below the turn figure beside it.
spend() {  # session cost-before cost-after
  rm -f /tmp/claude-statusline-*-"$1".txt
  for _c in "$2" "$3"; do
    printf '{"session_id":"%s","prompt_id":"p","model":{"display_name":"Claude Opus"},"context_window":{},"cost":{"total_cost_usd":%s}}' "$1" "$_c" | sh "$SCRIPT"
  done | tail -n 1
}
assert_contains "total: one decimal below \$10, truncated" "$(spend statusline-test-total 3.00 3.29)" "\$0.2 ⊂ \$3.2"
assert_contains "total: whole dollars from \$10"           "$(spend statusline-test-total 12.00 12.75)" "\$0.7 ⊂ \$12"
assert_contains "total: keeps its decimal under a turn"    "$(spend statusline-test-total 0.05 12.75)" "\$12.7 ⊂ \$12.7"
out=$(printf '{"session_id":"statusline-test-free","model":{"display_name":"Claude Opus"},"context_window":{},"cost":{"total_cost_usd":0}}' | sh "$SCRIPT")
assert_not_contains "spend: nothing spent, no segment" "$out" "⊂"

# --- Turns follow prompt_id --------------------------------------------------------
session=statusline-test-turns
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 1.000 null >/dev/null
out=$(render_pc "$session" p1 1.800 null)
assert_contains "turns: the turn is the growth since its prompt began" "$out" "\$0.8 "
out=$(render_pc "$session" p2 1.800 null)
assert_contains "turns: a new prompt shows the last turn until it bills" "$out" "\$0.8 "
out=$(render_pc "$session" p2 2.100 null)
assert_contains "turns: then only its own cost" "$out" "\$0.3 "

# Working: the spinner flower stands in for the "$" ("$" being its ninth frame).
session=statusline-test-working
rm -f /tmp/claude-statusline-*-"$session".txt
printf '{"type":"assistant","requestId":"r1","timestamp":"%s.000Z","message":{"stop_reason":"tool_use"}}\n' \
  "$(iso_of $((now - 5)))" > "$proj/$session.jsonl"
for _c in 1.000 1.500; do
  out=$(printf '{"session_id":"%s","prompt_id":"p","model":{"display_name":"Claude Opus"},"transcript_path":"%s","context_window":{},"cost":{"total_cost_usd":%s}}' \
    "$session" "$proj/$session.jsonl" "$_c" | sh "$SCRIPT")
done
plain=$(printf '%s' "$out" | sed 's/\x1b\[[0-9;]*m//g')
case "$plain" in *"·0.5 ⊂"*|*"✢0.5 ⊂"*|*"✳0.5 ⊂"*|*"✻0.5 ⊂"*|*"✽0.5 ⊂"*|*"\$0.5 ⊂"*) _r=ok ;; *) _r=bad ;; esac
assert_contains     "working: a flower frame leads the live figure" "$_r" ok
assert_not_contains "working: no idle age while working"            "$out" "0.5 -"

# --- Cache forecast: forms and blinking ---------------------------------------------
session=statusline-test-past-hour
rm -f /tmp/claude-statusline-*-"$session".txt
out=$(PC_AGE=4000 render_pc "$session" p1 5.000 "$(pc 1h $((now - 100)) 0 90000)")
assert_contains "past an hour: no TTL comparison" "$out" "(>1h⇒+=90K)"
# Above $CLAUDE_MISS_FLOOR (200K) the count blinks: red or plain, never its calm blue.
session=statusline-test-blink
rm -f /tmp/claude-statusline-*-"$session".txt
out=$(PC_AGE=400 render_pc "$session" p1 5.000 "$(pc 5m $((now - 10)) 0 300000)")
assert_contains "big rebuild: forecast shown" "$out" "⇒+=300K)"
case "$out" in *"${BLUE}230K"*) _r=bad ;; *) _r=ok ;; esac
assert_contains "big rebuild: the context count leaves its calm blue" "$_r" ok
out=$(CLAUDE_MISS_FLOOR=500000 PC_AGE=400 render_pc "$session" p1 5.000 "$(pc 5m $((now - 10)) 0 300000)")
case "$out" in *"${BLUE}230K"*) _r=ok ;; *) _r=bad ;; esac
assert_contains "big rebuild: below a raised floor the count stays blue" "$_r" ok
# Miss sizes from a million tokens up read in M.
session=statusline-test-miss-big
rm -f /tmp/claude-statusline-*-"$session".txt
render_pc "$session" p1 5.000 "$(pc 1h $((now + 3500)) 0 1300000)" >/dev/null
out=$(render_pc "$session" p1 9.000 "$(pc 1h $((now + 3500)) 1234567 1300000 '{"causes":["ttl_expired_1h"]}')")
assert_contains "miss size: a million and up reads in M" "$out" "(1.2M⏱)"

# --- Weekly quota: pace and working days on a fixed clock ------------------------------
# Wednesday 2026-10-14 12:00 UTC, the week resetting on Friday at noon: of its five
# working days, three have passed (60%) and two remain.
fixed=1791979200
mkdir -p "$TMP/fixclock"
printf '#!/bin/sh\n[ "$1" = "+%%s" ] && { echo %s; exit 0; }\nexec %s "$@"\n' "$fixed" "$(command -v date)" > "$TMP/fixclock/date"
chmod +x "$TMP/fixclock/date"
week() {  # used% seconds-to-reset
  rm -f "$HOME/.claude/quota.json" /tmp/claude-statusline-*-statusline-test-week.txt
  printf '{"session_id":"statusline-test-week","model":{"display_name":"Claude Opus"},"context_window":{},"rate_limits":{"seven_day":{"used_percentage":%s,"resets_at":%s}}}' \
    "$1" "$((fixed + $2))" | PATH="$TMP/fixclock:$PATH" TZ=UTC sh "$SCRIPT"
}
out=$(week 30 172800)
assert_contains "weekly: slack in hand is a positive pace" "$out" "+30=70% / 2wd"
case "$out" in *"${GREEN}+30"*) _r=ok ;; *) _r=bad ;; esac
assert_contains "weekly: slack is green" "$_r" ok
out=$(week 65 172800)
assert_contains "weekly: burning ahead is a negative pace" "$out" "-5=35% / 2wd"
case "$out" in *"${ORANGE}-5"*) _r=ok ;; *) _r=bad ;; esac
assert_contains "weekly: a small deficit is orange" "$_r" ok
out=$(week 80 172800)
case "$out" in *"${RED}-20"*) _r=ok ;; *) _r=bad ;; esac
assert_contains "weekly: ten points behind or more is red" "$_r" ok
out=$(week 60 172800)
assert_contains     "weekly: on pace shows no pace" "$out" " 40% / 2wd"
assert_not_contains "weekly: no +0"                 "$out" "0="
assert_contains "weekly: under a day reads in hours"   "$(week 10 18000)" "/ 5h"
assert_contains "weekly: under an hour reads in minutes" "$(week 10 2700)" "/ 45m"
# Friday noon to Monday noon spans a weekend: one working day, not three.
assert_contains "weekly: weekends do not count" "$(week 10 $((2 * 86400 + 3 * 86400)))" "/ 3wd"

# --- Location: the repository's name, then the branch -------------------------------
repo="$TMP/petclinic"
mkdir -p "$repo/backend"
git -C "$repo" init -q
git -C "$repo" symbolic-ref HEAD refs/heads/main
loc() {
  printf '{"session_id":"statusline-test-loc","model":{"display_name":"Claude Opus"},"context_window":{},"workspace":{"current_dir":"%s"}}' "$1" | sh "$SCRIPT"
}
out=$(loc "$repo/backend")
assert_contains     "location: names the repository, not the subdirectory" "$out" "petclinic"
assert_not_contains "location: no subdirectory name"                       "$out" "backend"
assert_not_contains "location: trunk shows no branch"                      "$out" "@"
git -C "$repo" symbolic-ref HEAD refs/heads/feat
assert_contains "location: another branch follows the name" "$(loc "$repo/backend")" "petclinic${RESET}@feat"
_a=$(loc "$repo" | sed -n 's/.*\(\x1b\[48;5;[0-9]*m\x1b\[38;5;[0-9]*m\)petclinic.*/\1/p')
_b=$(loc "$repo/backend" | sed -n 's/.*\(\x1b\[48;5;[0-9]*m\x1b\[38;5;[0-9]*m\)petclinic.*/\1/p')
[ -n "$_a" ] && [ "$_a" = "$_b" ] && _r=ok || _r=bad
assert_contains "location: one repository, one colour" "$_r" ok
out=$(loc "$TMP")
assert_contains "location: outside a repository, the directory's own name" "$out" "${TMP##*/}"

# --- Debug log ----------------------------------------------------------------------
touch "$HOME/.claude/statusline-debug"
sl statusline-test-debug "Claude Opus" "" '' >/dev/null
rm -f "$HOME/.claude/statusline-debug"
grep -q '"sid":"statusli"' "$HOME/.claude/statusline-debug.log" && grep -q ' OUT statusline ' "$HOME/.claude/statusline-debug.log" \
  && _r=ok || _r=bad
assert_contains "debug log: what was handed in and what was rendered" "$_r" ok

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
