#!/bin/bash

source ~/.dotfiles/bin/lib/interaction.sh
source ~/.dotfiles/bin/lib/dotfiles.sh

cd ~

if [ ! -d ~/.oh-my-zsh ]; then
    info "Installing oh-my-zsh..."
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
    # Remove zsh installation leftovers
    rm -f .zshrc .zshrc.pre-oh-my-zsh
    # Put the good stuff in place
    symlink .dotfiles/zshrc .zshrc
fi
