#!/bin/sh
# A plan change must use the account reading, even when a session's first
# status-line render mistakes cached headers for a fresh API response.
set -eu
cd "$(dirname "$0")"
STATE="$PWD/hooks/quota-state.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
mkdir -p "$HOME/.claude/hooks"
ln -s "$STATE" "$HOME/.claude/hooks/quota-state.sh"
now=$(date +%s)
reset=$((now + 3600))
old_reset=$((now + 4 * 3600))
week_reset=$((now + 2 * 86400))

# Max 5x -> Max 20x: the old session's first render appears fresh and its
# reset time is farther ahead. Neither may supersede the live account probe.
"$STATE" set 11 "$reset" 39 "$week_reset" >/dev/null
"$STATE" publish 99 "$old_reset" 97 "$week_reset" 1 >/dev/null
actual=$("$STATE" read | cut -d' ' -f1,4)
[ "$actual" = '11 probe' ] || { echo "FAIL: five-hour probe replaced by $actual"; exit 1; }
actual=$("$STATE" read7 | cut -d' ' -f1,4)
[ "$actual" = '39 probe' ] || { echo "FAIL: weekly probe replaced by $actual"; exit 1; }
echo 'ok: live account reading outranks a first-render cache in both windows'
