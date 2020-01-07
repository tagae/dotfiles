#!/bin/bash

XRDB=xrdb

# Add other possible paths of cpp here
for cpp in /usr/bin/cpp; do
    if test -x $cpp; then
        XRDB="$XRDB -cpp $cpp"
        break
    fi
done

for resource in ~/.Xresources ~/.Xresources.d/* ; do
    [ -r $resource ] && $XRDB -merge $resource
done
