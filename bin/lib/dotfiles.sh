source ~/.dotfiles/bin/lib/interaction.sh

function symlink {
    ln -s "$1" "$2" && info -h "Symlinked $1 to $2"
}

function rmlink {
    rm "$1" && info -h "Removed symlink $1"
}
