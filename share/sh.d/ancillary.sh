load () {
    [ -r "$1" ] && source "$1"
    [ -r "$1.sh" ] && source "$1.sh"
}

testcmd () {
    which "$1" 1>/dev/null 2>&1
}

optcmd () {
    testcmd "$1" && $*
}

prefcmd () {
    VAR=$1
    shift
    testcmd "$1" && export $VAR="$*"
}

relevantpath () {
    local var="$1"
    local dir="$2"
    [ -n "$var" -a -n "$dir" ] &&
    [[ ":\$$var:" != *":$dir:"* ]] &&
    [ -r "$dir" ]
}

prependpath () {
    local var="$1"
    shift
    for dir in $*; do
        relevantpath "$var" "$dir" && eval "export $var=\"$dir\${$var:+:\$$var}\""
    done
}

appendpath () {
    local var="$1"
    shift
    for dir in $*; do
        relevantpath "$var" "$dir" && eval "export $var=\"\${$var:+\$$var:}$dir\""
    done
}

setpath () {
    [ -d "$2" ] && eval "export $1=\"$2\""
}

addflag () {
    eval "$1=\"$2$3 \$$1\""
}