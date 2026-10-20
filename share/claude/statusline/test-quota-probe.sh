#!/bin/sh
# quota-probe.sh against a fake usage endpoint: what it records, where it logs, and
# that it respects its interval. Also checks quota-state.sh's command set.
#
#   ./test-quota-probe.sh
cd "$(dirname "$0")" || exit 2
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM
export HOME="$TMP"
mkdir -p "$HOME/.claude/hooks"
ln -s "$PWD/hooks/quota-state.sh" "$HOME/.claude/hooks/quota-state.sh"
PROBE="$PWD/hooks/quota-probe.sh"

pass=0
fail=0
check() {  # label, then a command that must succeed
  _label=$1; shift
  if "$@" >/dev/null 2>&1; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$_label"
  else
    fail=$((fail + 1)); printf 'FAIL  %s\n' "$_label"
  fi
}

now=$(date +%s)
cat > "$TMP/fetch.sh" <<SH
#!/bin/sh
echo 12 $((now + 3600)) 34 $((now + 86400)) 56 $((now + 86400)) Fable
SH
chmod +x "$TMP/fetch.sh"
export CLAUDE_WEEKLY_QUOTA_PROBE_COMMAND="$TMP/fetch.sh"

sh "$PROBE" --force
check "probe: succeeds against the endpoint"          test $? -eq 0
check "probe: stamps the attempt as ok"               grep -q ' ok$' "$HOME/.claude/quota-probe"
check "probe: logs to quota-probe.log"                grep -q 'probe five_hour=12% seven_day=34% Fable=56%' "$HOME/.claude/quota-probe.log"
check "probe: no log under the retired gate's name"   test ! -e "$HOME/.claude/quota-gate.log"
# shellcheck disable=SC2016  # the $1 belongs to the child shell
check "probe: both windows and the scoped cap stored" \
  sh -c '[ "$("$1" read | cut -d" " -f1,4)" = "12 probe" ] && [ "$("$1" reads | cut -d" " -f1,4)" = "56 Fable" ]' _ "$HOME/.claude/hooks/quota-state.sh"

sh "$PROBE"
check "probe: not due again within its interval (exit 2)" test $? -eq 2

"$HOME/.claude/hooks/quota-state.sh" readall >/dev/null 2>&1
check "quota-state: the gate-only readall command is gone" test $? -ne 0

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
