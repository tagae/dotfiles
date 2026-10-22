# Prompt and terminal appearance.

status is-interactive; or return

set -g fish_greeting ''

command -sq vivid
and set -x LS_COLORS (vivid --color-mode 8-bit generate snazzy)

command -sq starship
and starship init fish | source
