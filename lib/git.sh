test -v GIT_LIB && return || readonly GIT_LIB="${BASH_SOURCE}"

source "$(dirname "$GIT_LIB")"/base.sh

dotfiles_git() {
    git -C "$DOTFILES" "$@"
}
