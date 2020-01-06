test -v ENV_LIB && return || readonly ENV_LIB="${BASH_SOURCE}"

source "$(dirname "$ENV_LIB")"/path.sh

BIN="$(absolute_dirname "$0")"
LIB="$(absolute_dirname "$ENV_LIB")"
BASE="$(dirname "$LIB")"

DOTFILES="$BASE/share"
