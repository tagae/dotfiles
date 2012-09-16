if [ -n "$DOTFILES_LIB_GIT" ]; then
    return
else
    DOTFILES_LIB_GIT=true
fi

unset GIT_DIR # Defined for git hooks, but messes things up.

function committed-files {
    git diff-tree -r --name-only --no-commit-id "${1:-HEAD}"
}
