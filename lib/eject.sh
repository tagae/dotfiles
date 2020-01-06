test -v EJECT_LIB && return || readonly EJECT_LIB="${BASH_SOURCE}"

source "$(dirname "$EJECT_LIB")"/base.sh

require_module message path git

eject_dotfile() {
    local -r reference="$1"
    [[ -e "$reference" ]] || error "$reference does not exist"
    [[ -L "$reference" ]] || error "$reference is not a symbolic link"

    local absolute
    absolute="$(absolute_path "$reference")"
    [[ "$absolute" =~ ^"$HOME" ]] || error "$reference is not in your home directory"
    if [[ "$absolute" =~ ^"$DOTFILES" ]]; then
        error "$reference is part of your dotfiles directory"
    fi
    [[ "$absolute" =~ ^"$HOME"/\.(.+) ]] || error "$reference is not a dotfile"
    local -r relative="${BASH_REMATCH[1]}"

    local -r dotfile="$DOTFILES/$relative"
    [[ "$(realpath "$reference")" = "$(realpath "$dotfile")" ]] || \
        error "$reference does not refer to $(from_home "$dotfile")"

    expel_dotfile "$reference" "$dotfile"
    untrack_dotfile "$dotfile" "feat: eject $relative"

    info "moved $(from_home "$dotfile") back into ~/.$relative"
}

expel_dotfile() {
    local -r reference="$1" dotfile="$2"
    rm "$reference"
    mv "$dotfile" "$reference"
    find "$DOTFILES" -type d -empty -delete
}

untrack_dotfile() {
    local -r dotfile="$1" message="$2"
    dotfiles_git rm --quiet "$dotfile"
    dotfiles_git commit --quiet --message "$message"
}
