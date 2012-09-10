for map in ~/.Xmodmap ~/.Xmodmap-$(uname) ; do
    [ -r $map ] && xmodmap $map
done
