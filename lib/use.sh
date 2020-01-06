test -v USE_LIB && return || readonly USE_LIB="${BASH_SOURCE}"

source "$(dirname "$USE_LIB")"/base.sh

require_module message path

use_dotfile() {
    local -r dotfile="$1"
    [[ -e "$dotfile" ]] || error "$dotfile does not exist"

    local absolute
    absolute="$(absolute_path "$dotfile")"
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

    info "using $(from_home "$dotfile") as $pretty_reference"
}
