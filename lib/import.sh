test -v IMPORT_LIB && return || readonly IMPORT_LIB="${BASH_SOURCE[0]}"

source "$(dirname "$IMPORT_LIB")"/base.sh

require-module message path git use

import-dotfile() {
    local -r source="$1"
    [[ -e "$source" ]] || error "$source does not exist"
    [[ -L "$source" ]] && error "$source is a symbolic link"
    [[ "$(absolute-path "$source")" =~ ^"$HOME"/\.(.+) ]] || error "$source is not a dotfile"
    local -r relative="${BASH_REMATCH[1]}"
    local -r dotfile="$DOTFILES/$relative"
    if [[ -e "$dotfile" ]]; then
        error "import clashes with existing $(from-home "$dotfile")"
    fi

    ingest-dotfile "$source" "$dotfile"
    track-dotfile "$dotfile" "feat: import $relative"

    info "moved ~/.$relative to $(from-home "$dotfile")"

    use-dotfile "$dotfile"
}

ingest-dotfile() {
    local -r source="$1" dotfile="$2"
    mkdir -p "$(dirname "$dotfile")"
    mv "$source" "$dotfile"
}

track-dotfile() {
    local -r dotfile="$1" message="$2"
    dotfiles-git add "$dotfile"
    dotfiles-git commit --quiet --message "$message"
}
