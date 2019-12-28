test -v GIT_LIB && return || readonly GIT_LIB="${BASH_SOURCE[0]}"

source "$(dirname "$GIT_LIB")"/base.sh

dotfiles-git() {
    git -C "$DOTFILES" "$@"
}

dotfiles-is-git-repo() {
    dotfiles-git rev-parse --is-inside-work-tree 2> /dev/null
}

has-unstaged-changes() {
    ! dotfiles-git diff-files --quiet
}

has-staged-changes() {
    # works even if there is a file named HEAD
    ! dotfiles-git diff-index --cached --quiet HEAD --
}

has-untracked-files() {
    dotfiles-git ls-files --others --exclude-standard | grep -q .
}
