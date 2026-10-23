#!/bin/sh
# Preview the fade of the compact status line in this terminal, by running statusline-compact.sh
# on made-up payloads. The fade colours three things, each shown here:
#   - the cache countdown: the palette, one countdown per colour, and a strip of points across
#     the cache lifetime;
#   - the input tokens, by how much of the context window is used;
#   - the 5h quota percentage (the 7d one is coloured the same), by how much of it is used.
#
# Usage: ./fade-preview.sh [LIFETIME]
#   LIFETIME is the cache TTL as Claude Code reports it: a number and s, m or h (default 1h).

set -o errexit -o nounset

readonly points=60                  # the countdown strip has points + 1 cells
readonly sec_per_min=60
readonly sec_per_hour=3600

ttl=${1:-1h}
case "$ttl" in [1-9]*[smh]) ;; *) printf 'usage: %s [LIFETIME]  (such as 1h, 5m, 90s)\n' "$0" >&2; exit 1 ;; esac
n=${ttl%?}
case "$n" in *[!0-9]*) printf 'usage: %s [LIFETIME]  (such as 1h, 5m, 90s)\n' "$0" >&2; exit 1 ;; esac
case "$ttl" in
  *s) lifetime=$n ;;
  *m) lifetime=$((n * sec_per_min)) ;;
  *h) lifetime=$((n * sec_per_hour)) ;;
esac

script=${0%/*}/statusline-compact.sh
state_dir=$(mktemp -d)
trap 'rm -rf "$state_dir"' EXIT
esc=$(printf '\033')
nl=$(printf '\n_'); nl=${nl%_}

# run PAYLOAD -> the status line the script prints for it.
run() { printf '%s' "$1" | CLAUDE_STATUSLINE_STATE_DIR=$state_dir sh "$script"; }

# --- The cache countdown ---------------------------------------------------------------------

# segment SECONDS_LEFT -> the countdown as the status line prints it, icon and colour included.
segment() {
  run "$(printf '{"session_id":"fade-preview","prompt_cache":{"ttl":"%s","expires_at":%s}}' \
    "$ttl" $(($(date +%s) + $1)))" | sed 's/^[^(]*(\(.*\))$/\1/'
}

# colour_of SEGMENT -> its 256-colour number, nothing when it is plain.
colour_of() { printf '%s' "$1" | sed -n "s/.*${esc}\[38;5;\([0-9]*\)m.*/\1/p"; }

countdown_section() {
  local i=$points seg colour strip= seen= samples=
  while [ "$i" -ge 0 ]; do
    # The middle of each point's slice of the lifetime, so the countdown reads as a round figure.
    seg=$(segment $((lifetime * i / points + lifetime / (2 * points))))
    colour=$(colour_of "$seg")
    if [ -n "$colour" ]; then strip="$strip$(printf '%s[48;5;%sm  %s[0m' "$esc" "$colour" "$esc")"
    else strip="$strip$(printf '%s[7m  %s[0m' "$esc" "$esc")"
    fi
    case " $seen " in
      *" ${colour:-plain} "*) ;;
      *) seen="$seen ${colour:-plain}"; samples="$samples$seg   ${colour:-plain}$nl" ;;
    esac
    i=$((i - 1))
  done
  samples="$samples$(segment -120)   expired$nl"

  printf 'Cache countdown, lifetime %s\n\nPalette, in fade order:\n' "$ttl"
  for colour in $seen; do
    [ "$colour" = plain ] || printf '%s[48;5;%sm        %s[0m  %s\n' "$esc" "$colour" "$esc" "$colour"
  done
  printf '\nCountdown, one per colour (plain is the terminal'"'"'s own text colour):\n%s' "$samples"
  printf '\nStrip, lifetime just started (left) to about to expire (right); plain is reverse video:\n%s\n' "$strip"
}

# --- The input tokens and the quota percentage -----------------------------------------------

# render_input USED -> the input figure, "↑87K/200K" (a 200K window).
render_input() {
  local out
  out=$(run "$(printf '{"session_id":"fade-preview","context_window":{"used_percentage":%s,"context_window_size":200000,"total_input_tokens":%s}}' \
    "$1" $((2000 * $1)))")
  printf '↑%s' "${out#*↑}"
}
# render_quota USED -> the 5h quota figure, "⧖ 37%".
render_quota() {
  local out
  out=$(run "$(printf '{"session_id":"fade-preview","rate_limits":{"five_hour":{"used_percentage":%s}}}' "$1")")
  printf '⧖%s' "${out#*⧖}"
}

# section TITLE RENDER PREFIX: a table every 10% and a strip every 2%.
# PREFIX is what the figure starts with, up to its colour.
section() {
  local title=$1 render=$2 prefix=$3 used c strip=
  printf '\n%s\n\n' "$title"
  used=0
  while [ "$used" -le 100 ]; do
    printf '%-6s %s\n' "${used}%" "$($render "$used")"
    used=$((used + 10))
  done
  used=0
  while [ "$used" -le 100 ]; do
    c=$($render "$used" | sed -n "s/^${prefix}${esc}\[38;5;\([0-9]*\)m.*/\1/p")
    strip="$strip$(printf '%s[48;5;%sm %s[0m' "$esc" "${c:-249}" "$esc")"
    used=$((used + 2))
  done
  printf '\nStrip, used 0%% (left) to 100%% (right), every 2%%:\n%s\n' "$strip"
}

countdown_section
section 'Input tokens, by context used' render_input '↑'
section 'Quota percentage (5h and 7d alike), by quota used' render_quota '⧖ '
