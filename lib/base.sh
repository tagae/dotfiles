test -v BASE_LIB && return || readonly BASE_LIB="${BASH_SOURCE}"

set -o nounset -o pipefail -o errexit -o errtrace -o functrace -o posix
test -v DEBUG && set -o xtrace

trap 'echo "[BUG] command '"'"'$BASH_COMMAND'"'"' failed at $BASH_SOURCE:$LINENO" >&2' ERR

source "$(dirname "$BASE_LIB")"/env.sh

require_module() {
    while (( $# > 0 )); do
        source "$LIB/$1.sh"
        shift
    done
}
