test -v PATH_LIB && return || readonly PATH_LIB="${BASH_SOURCE[0]}"

absolute-dirname() {
    (
        cd "$(dirname "$1")"
        pwd
    )
}

absolute-path() {
    local -r file="$1"
    echo "$(absolute-dirname "$file")/$(basename "$file")"
}

from-home() {
    local -r path="$1"
    local absolute
    absolute="$(absolute-path "$path")"
    if test "$absolute" = "$HOME"; then
        echo '~'
    else
        local relative="${absolute##$HOME/}"
        if test "$absolute" = "$relative"; then
            echo "$path" # could not relativize
        else
            echo "~/$relative"
        fi
    fi
}
