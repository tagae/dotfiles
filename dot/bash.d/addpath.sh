#!/bin/sh

addpath () {
    # defaults
    local prefix=1
    local verbose=0
    local sep=:
    # options
    OPTIND=1
    while getopts pvs:m: var
    do
        case "$var" in
            p) prefix=1 ;;
            v) verbose=1 ;;
            s) sep=$OPTARG ;;
            m) mark=$OPTARG ;;
        esac
    done
    shift $(($OPTIND-1))
    local var=$1
    shift
    local elt
    for elt; do
        local cur=$(eval echo "\$$var")
        case $cur in
            *$elt*)
               [ $verbose -eq 1 ] && echo "addpath: $elt already in $var" >&2
               continue
               ;;
        esac
        if [ -r "$elt" ]; then
            local item=$mark$elt
            if eval test -n "\"\$$var\""; then
                if [ $prefix -eq 1 ]; then
                    eval $var="\$item\$sep\$$var"
                else
                    eval $var="\$$var\$sep\$item"
                fi
            else
                eval $var="\$item"
            fi
            eval "export $var" # notice
        else
            [ $verbose -eq 1 ] && echo "addpath: $elt is not readable" >&2
            continue
        fi
    done
}

addflag () {
    local var=$1
    local mark=$2
    shift 2
    addpath -s ' ' -m "$mark" "$var" $@
}

setpath () {
    local var=$1
    local value=$2
    eval unset "$var"
    addpath $var $value
}
