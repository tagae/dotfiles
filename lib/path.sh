test -v PATH_LIB && return || readonly PATH_LIB="${BASH_SOURCE}"

absolute_dirname() {
    absolute_path "$(dirname "$1")"
}

absolute_path() {
    realpath --canonicalize-missing --no-symlinks "$1"
}

from_home() {
    echo -n "~/"
    realpath --canonicalize-missing --no-symlinks --relative-to "$HOME" "$1"
}
