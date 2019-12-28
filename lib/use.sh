test -v USE_LIB && return || readonly USE_LIB="${BASH_SOURCE[0]}"

source "$(dirname "$USE_LIB")"/base.sh

require-module message path

use-dotfile() {
    local -r dotfile="$1"
    [[ -e "$dotfile" ]] || error "$dotfile does not exist"

    local absolute
    absolute="$(absolute-path "$dotfile")"
    [[ "$absolute" =~ ^"$DOTFILES"/(.+) ]] || error "$dotfile is not a managed dotfile"
    local -r relative="${BASH_REMATCH[1]}"

    local -r reference="$HOME/.$relative" pretty_reference="~/.$relative"
    if [[ -e "$reference" ]]; then
        if [[ -L "$reference" ]]; then
            if [[ "$(realpath "$reference")" = "$(realpath "$dotfile")" ]]; then
                info "$dotfile is already in use at $pretty_reference"
                return # success
            fi
        fi
        error "file $pretty_reference exists"
    fi

    mkdir -p "$(dirname "$reference")"
    ln --relative --symbolic "$dotfile" "$reference"

    local -r pretty_dotfile="~/$(relative-to "$HOME" "$dotfile")"
    info "using $pretty_dotfile as $pretty_reference"
}
