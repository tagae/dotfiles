#!/bin/sh

testcmd () {
    which "$1" > /dev/null 2>&1
}

optcmd () {
    cmd=$(which "$1" 2>/dev/null)
    shift
    if test -n "$cmd"; then
        $cmd $@
    fi
}

prefcmd () {
    VAR=$1
    CMD=$2
    testcmd "$CMD" && export $VAR=$CMD
}
