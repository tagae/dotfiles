#!/bin/sh

function cdd ()
{
    clear
    # only change directory if a directory is specified
    [ -n "${1}" ] && cd "$1"
    # filesystem stats
    echo "`df -h .`"
    echo ""
    echo -n "[`pwd`:"
    # count files
    echo -n " <`find . -maxdepth 1 -mindepth 1 -type f | wc -l |
                tr -d '[:space:]'` files>"
    # count sub-directories
    echo -n " <`find . -maxdepth 1 -mindepth 1 -type d | wc -l |
                tr -d '[:space:]'` dirs/>"
    # count links
    echo -n " <`find . -maxdepth 1 -mindepth 1 -type l | wc -l |
                tr -d '[:space:]'` links@>"
    # total disk space used by this directory and all subdirectories
    echo " <~`du -sh . 2> /dev/null | cut -f1`>]"

    ROWS=`stty size | cut -d' ' -f1`
    FILES=`find . -maxdepth 1 -mindepth 1 |
    wc -l | tr -d '[:space:]'`
    # if the terminal has enough lines, do a long listing
    if [ `expr "${ROWS}" - 6` -lt "${FILES}" ]; then
            ls -ACF
    else
            ls -hlAF
    fi
}
