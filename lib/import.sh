test -v IMPORT_LIB && return || readonly IMPORT_LIB="${BASH_SOURCE}"

source "$(dirname "$IMPORT_LIB")"/base.sh

require_module message path git use

import_dotfile() {
    local -r source="$1"
    [[ -e "$source" ]] || error "$source does not exist"
    [[ -L "$source" ]] && error "$source is a symbolic link"
    [[ "$(absolute_path "$source")" =~ ^"$HOME"/\.(.+) ]] || error "$source is not a dotfile"
    local -r relative="${BASH_REMATCH[1]}"
    local -r dotfile="$DOTFILES/$relative"
    if [[ -e "$dotfile" ]]; then
        error "import clashes with existing $(from_home "$dotfile")"
    fi

    ingest_dotfile "$source" "$dotfile"
    track_dotfile "$dotfile" "feat: import $relative"

    info "moved ~/.$relative to $(from_home "$dotfile")"

    use_dotfile "$dotfile"
}

ingest_dotfile() {
    local -r source="$1" dotfile="$2"
    mkdir -p "$(dirname "$dotfile")"
    mv "$source" "$dotfile"
}

track_dotfile() {
    local -r dotfile="$1" message="$2"
    dotfiles_git add "$dotfile"
    dotfiles_git commit --quiet --message "$message"
}
