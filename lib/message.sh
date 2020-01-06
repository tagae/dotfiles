test -v MESSAGE_LIB && return || readonly MESSAGE_LIB="${BASH_SOURCE}"

info() {
    if test -t 1; then echo -n "[$(tput setaf 7)Info$(tput sgr0)] "; fi
    echo "$@"
}

warn() {
    if  test -t 1; then echo -n "[$(tput setaf 3)Warn$(tput sgr0)] "; fi
    echo "$@"
}

error() {
    if test -t 2; then echo -n "[$(tput bold)$(tput setaf 1)Error$(tput sgr0)] "; fi
    echo "$@" >&2
    exit 1
}
