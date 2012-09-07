#!/bin/sh

if [ -d ~/.xinitrc.d ]; then
    for f in ~/.xinitrc.d/*.sh; do
        [ -x "$f" ] && source "$f"
    done
    unset f
fi
