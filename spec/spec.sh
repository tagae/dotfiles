test -v SPEC_LIB && return || readonly SPEC_LIB="${BASH_SOURCE}"

set -o nounset -o posix
test -v DEBUG && set -o xtrace

trap 'echo "[Trace] command '"'"'$BASH_COMMAND'"'"' failed at $BASH_SOURCE:$LINENO" >&2' ERR

SPEC_NAME="$(basename "$0")"
SPEC_DIR="$(realpath "$(dirname "$0")")"

declare -a FILES_TO_CLEAN=()
declare -i PASS=0 FAIL=0

HOME="$(mktemp -d "$SPEC_DIR"/"$SPEC_NAME"-fixture-XXX)" # synonym of ~

trap cleanup EXIT

cleanup() {
    rm -f "${FILES_TO_CLEAN[@]}"
    if [[ "$HOME" =~ .*-fixture-[[:alnum:]]{3}$ ]]; then
        rm -rf "$HOME"
    else
        echo "Unexpected HOME value: $HOME" >&2
    fi
}

pass() {
    if test -t 1; then
        echo -n "[$(tput bold)$(tput setaf 2)Pass$(tput sgr0)] "
    else
        echo -n "[Pass] "
    fi
    echo "$@"
    (( PASS++ ))
}

fail() {
    if test -t 1; then
        echo -n "[$(tput bold)$(tput setaf 1)Fail$(tput sgr0)] "
    else
        echo -n "[Fail] "
    fi
    echo "$@"
    (( FAIL++ ))
}

report_lines_as() {
    local -r label="$1" file="$2"
    if [ -f "$file" ]; then
        local line
        while read line; do
            [ -n "$line" ] && printf '%6s %s: %s\n' '' "$label" "$line"
        done < "$file"
        rm "$file"
    fi
}

create_file() {
    local -r file="$1" content="${2:-}"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
    [[ "$(realpath "$file")" =~ ^"$HOME" ]] || FILES_TO_CLEAN+="$file"
}

### ---[ spec domain-specific language ]---

Feature() {
    while [[ "${1:-}" =~ [[:punct:]]+ ]]; do shift; done
    echo
    echo ========= Feature: "$@"
    echo
}

Given() {
    if [[ "$*" =~ ^'a file '(.+)' with content '(.+)$ ]]; then
        create_file "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    elif [[ "$*" =~ ^'a file '(.+)$ ]]; then
        create_file "${BASH_REMATCH[1]}"
    elif [[ "$*" =~ ^'a directory '(.+)$ ]]; then
        local -r directory="${BASH_REMATCH[1]}"
        mkdir -p "$directory"
    elif [[ "$*" =~ ^'that '(.+)' contains '(.+)' file's?$ ]]; then
        local -r directory="${BASH_REMATCH[1]}"
        local -ri count="${BASH_REMATCH[2]}"
        Given an existing directory "$directory"
        local -ri actual="$(ls -1q "$directory" | wc -l)"
        (( $actual == "$count" )) \
            || fail "Fixture $directory contains $actual instead of $count files"
    elif [[ "$*" =~ ^'a symlink '(.+)' pointing to '(.+)$ ]]; then
        local -r symlink="${BASH_REMATCH[1]}" target="${BASH_REMATCH[2]}"
        Given that file "$target" exists
        mkdir -p "$(dirname "$symlink")"
        ln -fs "$target" "$symlink"
    elif [[ "$*" =~ ^'variable '(.+)' containing the path of the dotfiles git repository'$ ]]; then
        local -r varname="${BASH_REMATCH[1]}"
        eval "$varname=\"$(git -C "$HOME" rev-parse --show-toplevel)\""
    elif (( $# > 0 )) && [ "$1" = 'that' ]; then
        shift
        Assert "$@"
    fi
}

Thus() {
    if (( $? == 0 )); then
        pass "$@"
    else
        fail "$@"
    fi
    report_lines_as 'message' ~/stdout
    report_lines_as 'error message' ~/stderr
}

And() {
    Thus "$@"
}

End() {
    echo
    echo $PASS tests passed
    echo $FAIL tests failed
    (( FAIL == 0 ))
}

Assert() {
    if [[ "$*" =~ ^'the symlink '(.+)' points to '(.+)$ ]]; then
        local -r symlink="${BASH_REMATCH[1]}" target="${BASH_REMATCH[2]}"
        Given that symlink "$symlink" exists
        Given that "$target" exists
        test "$(realpath "$symlink")" = "$(realpath "$target")" \
             || fail "fixture symlink $symlink should point to $target"
    elif [[ "$*" =~ ^'file '(.+)' exists'$ ]]; then
        local -r file="${BASH_REMATCH[1]}"
        test -f "$file" || fail "fixture should contain file $file"
    elif [[ "$*" =~ ^'directory '(.+)' exists'$ ]]; then
        local -r directory="${BASH_REMATCH[1]}"
        test -d "$directory" || fail "fixture should contain directory $directory"
    elif [[ "$*" =~ ^'symlink '(.+)' exists'$ ]]; then
        local -r symlink="${BASH_REMATCH[1]}"
        test -L "$symlink" || fail "fixture should contain symlink $symlink"
    elif [[ "$*" =~ ^(.+)' exists'$ ]]; then
        local -r path="${BASH_REMATCH[1]}"
        test -e "$path" || fail "fixture should contain $path"
    elif [[ "$*" =~ ^'file '(.+)' does not exist'$ ]]; then
        local -r filename="${BASH_REMATCH[1]}"
        if test -f "$filename"; then
            fail "fixture should not contain file $filename"
        fi
    else
        fail Unmatched step: "$*"
    fi
}
