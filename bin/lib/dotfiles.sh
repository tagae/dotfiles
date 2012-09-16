if [ -n "$DOTFILES_LIB_DOTFILES" ]; then
    return
else
    DOTFILES_LIB_DOTFILES=true
fi

source ~/.dotfiles/bin/lib/interaction.sh

function symlink {
    ln -s "$1" "$2" && info -h "Symlinked $1 to $2${3:+ in $3}"
}

function rmlink {
    rm "$1" && info -h "Removed symlink $1"
}
