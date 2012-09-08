function committed-files {
    git diff-tree -r --name-only --no-commit-id "${1:-HEAD}"
}
