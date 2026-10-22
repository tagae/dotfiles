for path in /opt/local/share/fonts ; do
    [ -d $path ] && xset +fp $path
done

xset fp rehash
