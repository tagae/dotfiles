# Note that Fish sources conf.d/ before this file.

# Personal and third-party binaries.

fish_add_path $HOME/.local/bin

# Default programs.

command -sq emacs
and set -x EDITOR 'emacs -nw'

command -sq less
and set -x PAGER less

# Machine-specific settings and secrets.
set -l secrets ~/.config/fish/secrets.fish
test -f $secrets
and source $secrets
