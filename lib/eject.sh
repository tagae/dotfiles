test -v EJECT_LIB && return || readonly EJECT_LIB="${BASH_SOURCE[0]}"

source "$(dirname "$EJECT_LIB")"/base.sh

require-module message path git

eject-dotfile() {
    local -r reference="$1"
    [[ -e "$reference" ]] || error "$reference does not exist"
    [[ -L "$reference" ]] || error "$reference is not a symbolic link"

    local absolute
    absolute="$(absolute-path "$reference")"
    [[ "$absolute" =~ ^"$HOME" ]] || error "$reference is not in your home directory"
    if [[ "$absolute" =~ ^"$DOTFILES" ]]; then
        error "$reference is part of your dotfiles directory"
    fi
    [[ "$absolute" =~ ^"$HOME"/\.(.+) ]] || error "$reference is not a dotfile"
    local -r relative="${BASH_REMATCH[1]}"

    local -r dotfile="$DOTFILES/$relative"
    local -r pretty_dotfile="~/$(relative-to "$HOME" "$dotfile")"
    [[ "$(realpath "$reference")" = "$(realpath "$dotfile")" ]] || \
        error "$reference does not refer to $pretty_dotfile"

    expel-dotfile "$reference" "$dotfile"
    untrack-dotfile "$dotfile" "feat: eject $relative"

    info "moved $pretty_dotfile back into ~/.$relative"
}

expel-dotfile() {
    local reference="$1" dotfile="$2"
    rm "$reference"
    mv "$dotfile" "$reference"
    find "$DOTFILES" -type d -empty -delete
}

untrack-dotfile() {
    local dotfile="$1" message="$2"
    dotfiles-git rm --quiet "$dotfile"
    dotfiles-git commit --quiet --message "$message"
}
