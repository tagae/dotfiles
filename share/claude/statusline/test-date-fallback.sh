#!/bin/sh
# Tests the BSD/GNU fallbacks for `date` and `stat`. The same job has two
# spellings -- a file's mtime is `stat -f %m` on BSD and `stat -c %Y` on GNU;
# an ISO time to an epoch is `date -j -f` on BSD and `date -d` on GNU -- and the
# scripts carry both. The real tools on whatever machine runs this can only ever
# exercise ONE spelling, so this harness puts fake `date` and `stat` first on
# PATH and forces each flavour in turn:
#
#   bsd      only the BSD spelling works
#   gnu      only the GNU spelling works -- and GNU's `stat -f` behaves the way
#            the real one does: exit 1, but a block of filesystem info on STDOUT
#   neither  everything fails -- the value has to degrade to empty, not crash
#
# The fakes answer fixed values (an mtime of 1700000000, an epoch of
# 1790000000) and pass every other invocation through to the real tool,
# so the scripts under test run unmodified. Every helper is lifted verbatim from
# the shipped script, never re-typed here, so a change to it is a change under
# test.
#
#   ./test-date-fallback.sh
cd "$(dirname "$0")" || exit 2
SCRIPT="$PWD/statusline-fancy.sh"
PROBE="$PWD/hooks/quota-probe.sh"
REAL_DATE=$(command -v date)
REAL_STAT=$(command -v stat)

TMP=$(mktemp -d)
cleanup() {
  rm -rf "$TMP"
  rm -f /tmp/claude-statusline-*-statusline-test-datefb-*.txt 2>/dev/null
  rm -f /tmp/claude-turn-statusline-test-datefb-*.state 2>/dev/null
}
trap cleanup EXIT INT TERM
export HOME="$TMP/home"
mkdir -p "$HOME/.claude"

pass=0
fail=0

assert_eq() {
  label=$1 actual=$2 expected=$3
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1)); printf 'ok    %s\n' "$label"
  else
    fail=$((fail + 1))
    printf 'FAIL  %s\n      expected: %s\n      got:      %s\n' "$label" "$expected" "$actual"
  fi
}

# assert_has / assert_lacks "<label>" "<haystack>" "<needle>" (ANSI stripped)
assert_has() {
  plain=$(printf '%s' "$2" | sed 's/\x1b\[[0-9;]*m//g')
  case "$plain" in
    *"$3"*) pass=$((pass + 1)); printf 'ok    %s\n' "$1" ;;
    *) fail=$((fail + 1)); printf 'FAIL  %s\n      expected to find: %s\n      got:              %s\n' "$1" "$3" "$plain" ;;
  esac
}
assert_lacks() {
  plain=$(printf '%s' "$2" | sed 's/\x1b\[[0-9;]*m//g')
  case "$plain" in
    *"$3"*) fail=$((fail + 1)); printf 'FAIL  %s\n      expected NOT to find: %s\n      got:                  %s\n' "$1" "$3" "$plain" ;;
    *) pass=$((pass + 1)); printf 'ok    %s\n' "$1" ;;
  esac
}
assert_absent() {
  if [ ! -e "$2" ]; then pass=$((pass + 1)); printf 'ok    %s\n' "$1"
  else fail=$((fail + 1)); printf 'FAIL  %s\n      %s exists\n' "$1" "$2"; fi
}

# --- the fake tools -----------------------------------------------------------
# One directory per mode; `d-called` is touched if BSD's `date -d` is ever
# reached. On BSD that flag means "set the kernel's DST value", not "parse this
# date", so no code path may get there.
DATE_SHIM='#!/bin/sh
mode=@MODE@
clock() { case "$1" in *%a*) echo "Wed 12:34" ;; *) echo "12:34" ;; esac; }
[ "$1" = -u ] && [ "$2" = -d ] && shift
case "$1" in
  -r) if [ "$mode" = bsd ]; then clock "$3"; exit 0; fi
      echo "date: $2: No such file or directory" >&2; exit 1 ;;
  -j) if [ "$mode" = bsd ]; then
        case "$*" in *garbage*) echo "date: failed conversion" >&2; exit 1 ;; esac
        echo 1790000000; exit 0
      fi
      echo "date: invalid option -- j" >&2; exit 1 ;;
  --version) if [ "$mode" = gnu ]; then echo "date (GNU coreutils) 9.5"; exit 0; fi
      echo "date: illegal option -- -" >&2; exit 1 ;;
  -d) if [ "$mode" = gnu ]; then
        case "$2" in @*) clock "$3" ;; *) echo 1790000000 ;; esac; exit 0
      fi
      [ "$mode" = bsd ] && : > "@DIR@/d-called"
      echo "date: invalid date $2" >&2; exit 1 ;;
esac
exec "@REAL_DATE@" "$@"
'
STAT_SHIM='#!/bin/sh
mode=@MODE@
emit() { fmt=$1; shift
  for f in "$@"; do case "$fmt" in
    "%Y"|"%m") echo 1700000000 ;;
    "%Y %n"|"%m %N") echo "1700000000 $f" ;;
  esac; done; }
case "$1" in
  -c) if [ "$mode" = gnu ]; then fmt=$2; shift 2; emit "$fmt" "$@"; exit 0; fi
      echo "stat: illegal option -- c" >&2; exit 1 ;;
  -f) if [ "$mode" = bsd ]; then fmt=$2; shift 2; emit "$fmt" "$@"; exit 0; fi
      if [ "$mode" = gnu ]; then
        # GNU: -f is --file-system. Exit 1, but the report still goes to stdout.
        printf "  File: \"%s\"\n    ID: 0 Namelen: 255     Type: tmpfs\n" "$3"
        echo "stat: cannot read file system information for %m" >&2; exit 1
      fi
      echo "stat: illegal option -- f" >&2; exit 1 ;;
esac
exec "@REAL_STAT@" "$@"
'
mkshim() { # mode
  mkdir -p "$TMP/$1"
  for tool in date stat; do
    case $tool in date) tpl=$DATE_SHIM ;; stat) tpl=$STAT_SHIM ;; esac
    printf '%s' "$tpl" | sed -e "s#@MODE@#$1#g" -e "s#@DIR@#$TMP/$1#g" \
      -e "s#@REAL_DATE@#$REAL_DATE#g" -e "s#@REAL_STAT@#$REAL_STAT#g" > "$TMP/$1/$tool"
    chmod +x "$TMP/$1/$tool"
  done
}
for m in bsd gnu neither; do mkshim "$m"; done

# extract <file> <name>: one function's source, one-line or multi-line, verbatim.
extract() {
  src=$(awk -v n="$2" '
    index($0, n "() {") == 1 { print; if ($0 ~ /}[ \t]*$/) exit; p = 1; next }
    p { print; if ($0 ~ /^}/) exit }' "$1")
  if [ -z "$src" ]; then echo "FAIL  could not find $2() in $1"; exit 1; fi
  printf '%s\n' "$src"
}

# --- file_mtime / files_mtime: stat -----------------------------------------
eval "$(extract "$SCRIPT" file_mtime)"
eval "$(extract "$SCRIPT" files_mtime)"
for m in bsd gnu; do
  out=$( PATH="$TMP/$m:$PATH"; file_mtime /some/file 2>&1 )
  assert_eq "file_mtime, $m stat: just the mtime (no filesystem report)" "$out" "1700000000"
  out=$( PATH="$TMP/$m:$PATH"; files_mtime /d/a.jsonl /d/b.jsonl 2>&1 )
  assert_eq "files_mtime, $m stat: one '<mtime> <path>' line per file" "$out" \
"1700000000 /d/a.jsonl
1700000000 /d/b.jsonl"
done
out=$( PATH="$TMP/neither:$PATH"; file_mtime /some/file 2>&1 )
assert_eq "file_mtime, neither works: empty and silent" "$out" ""
out=$( PATH="$TMP/neither:$PATH"; files_mtime /d/a.jsonl 2>&1 )
assert_eq "files_mtime, neither works: empty and silent" "$out" ""
# The reason for the GNU-first order: the BSD-first form on GNU pollutes stdout.
out=$( PATH="$TMP/gnu:$PATH"; stat -f %m /some/file 2>/dev/null )
assert_has "premise: GNU's own stat -f writes a report to stdout" "$out" "File:"

# --- quota-probe.sh: iso_to_epoch and the lock's mtime ----------------------
eval "$(extract "$PROBE" iso_to_epoch)"
for m in bsd gnu; do
  out=$( PATH="$TMP/$m:$PATH"; iso_to_epoch "2026-09-20T12:00:00.123+00:00" 2>&1 )
  assert_eq "probe iso_to_epoch, $m date (fractional seconds, +00:00)" "$out" "1790000000"
done
out=$( PATH="$TMP/neither:$PATH"; iso_to_epoch "2026-09-20T12:00:00+00:00" 2>&1 )
assert_eq "probe iso_to_epoch, neither works: empty and silent" "$out" ""
out=$( PATH="$TMP/bsd:$PATH"; iso_to_epoch "garbage" 2>&1 )
assert_eq "probe iso_to_epoch, bsd, unparsable: empty and silent" "$out" ""
assert_absent "probe iso_to_epoch never fell through to BSD's date -d" "$TMP/bsd/d-called"

lock_line=$(grep '^  _lock_at=\$(stat' "$PROBE")
if [ -z "$lock_line" ]; then echo "FAIL  could not find the _lock_at= line in $PROBE"; exit 1; fi
LOCK=/some/lock
for m in bsd gnu; do
  out=$( PATH="$TMP/$m:$PATH"; eval "$lock_line" 2>&1; printf '%s' "$_lock_at" )
  assert_eq "probe lock mtime, $m stat" "$out" "1700000000"
done
out=$( PATH="$TMP/neither:$PATH"; eval "$lock_line" 2>&1; printf '[%s]' "$_lock_at" )
assert_eq "probe lock mtime, neither works: empty and silent" "$out" "[]"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
