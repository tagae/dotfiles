test -v ENV_LIB && return || readonly ENV_LIB="${BASH_SOURCE[0]}"

source "$(dirname "$ENV_LIB")"/path.sh

BIN="$(absolute-dirname "$0")"
LIB="$(absolute-dirname "$ENV_LIB")"
BASE="$(dirname "$LIB")"

DOTFILES="$BASE/share"
