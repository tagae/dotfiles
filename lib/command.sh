test -v COMMAND_LIB && return || readonly COMMAND_LIB="${BASH_SOURCE}"

use_command() {
    local role="$1" cmd
    shift
    while (( $# > 0 )); do
        if cmd=$(command -v "$1"); then
            eval "$role() { $cmd "'"$@"'"; }"
            declare -f "$role" > /dev/null
            return # use first found
        fi
        shift
    done
    error "could not find any variant of '$role'"
}
