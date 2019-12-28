test -v SPEC_LIB && return || readonly SPEC_LIB="${BASH_SOURCE[0]}"

set -o nounset
test -v DEBUG && set -o xtrace

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

report-lines-as() {
    local -r label="$1" file="$2"
    if [ -f "$file" ]; then
        local line
        while read line; do
            [ -n "$line" ] && printf '%6s %s: %s\n' '' "$label" "$line"
        done < "$file"
        rm "$file"
    fi
}

create-file() {
    local -r file="$1" content="${2:-}"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
    # mark for cleaning if file does not reside under HOME directory
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
    # effects
    if [[ "$*" =~ ^'a file '(.+)' with content '(.+)$ ]]; then
        create-file "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    elif [[ "$*" =~ ^'a file '(.+)$ ]]; then
        create-file "${BASH_REMATCH[1]}"
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
        Given a file "$target"
        mkdir -p "$(dirname "$symlink")"
        ln -fs "$target" "$symlink"
    elif [[ "$*" =~ ^'variable '(.+)' containing the path of the dotfiles git repository'$ ]]; then
        local -r varname="${BASH_REMATCH[1]}"
        eval "$varname=\"$(git -C "$HOME" rev-parse --show-toplevel)\""

    # assertions
    elif [[ "$*" =~ ^'that the symlink '(.+)' points to '(.+)$ ]]; then
        local -r symlink="${BASH_REMATCH[1]}" target="${BASH_REMATCH[2]}"
        Given an existing symlink "$symlink"
        Given an existing file "$target"
        test "$(realpath "$symlink")" = "$(realpath "$target")" \
             || fail "fixture symlink $symlink should point to $target"
    elif [[ "$*" =~ ^'an existing file '(.+)$ ]]; then
        local -r file="${BASH_REMATCH[1]}"
        test -f "$file" || fail "fixture should contain file $file"
    elif [[ "$*" =~ ^'an existing directory '(.+)$ ]]; then
        local -r directory="${BASH_REMATCH[1]}"
        test -d "$directory" || fail "fixture should contain directory $directory"
    elif [[ "$*" =~ ^'an existing symlink '(.+)$ ]]; then
        local -r symlink="${BASH_REMATCH[1]}"
        test -L "$symlink" || fail "fixture should contain symlink $symlink"
    elif [[ "$*" =~ ^'that file '(.+)' does not exist'$ ]]; then
        local -r filename="${BASH_REMATCH[1]}"
        test -f "$filename" && fail "fixture should not contain file $filename"
    else
        fail Unmatched step: Given "$*"
    fi
}

Thus() {
    if (( $? == 0 )); then
        pass "$@"
    else
        fail "$@"
    fi
    report-lines-as 'message' ~/stdout
    report-lines-as 'error message' ~/stderr
}

End() {
    echo
    echo $PASS tests passed
    echo $FAIL tests failed
    (( FAIL == 0 ))
}
