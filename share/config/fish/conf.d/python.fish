# Python setup.

fish_add_path $HOME/.pyenv/bin

command -sq pyenv
and set -x PYENV_ROOT $HOME/.pyenv
and pyenv init - | source
