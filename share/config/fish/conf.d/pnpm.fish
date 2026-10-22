# pnpm: Node packages.

test -d ~/Library/pnpm
and set -x PNPM_HOME $HOME/Library/pnpm
and fish_add_path --path --move $PNPM_HOME/bin
