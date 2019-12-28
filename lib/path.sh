test -v PATH_LIB && return || readonly PATH_LIB="${BASH_SOURCE[0]}"

absolute-dirname() {
    ( cd "$(dirname "$1")"; pwd; )
}

absolute-path() {
    local -r file="$1"
    echo "$(absolute-dirname "$file")/$(basename "$file")"
}

relative-to() {
    local -r dir="$1" file="$2"
    [[ "$file" =~ ^"$dir"/(.+) ]]
    echo "${BASH_REMATCH[1]}"
}
