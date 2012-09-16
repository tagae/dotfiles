if [ -n "$DOTFILES_LIB_INTERACTION" ]; then
    return
else
    DOTFILES_LIB_INTERACTION=true
fi

source ~/.dotfiles/bin/lib/colors.sh

termInfo=$(tput setaf 7)
termHighlight=$(tput setaf 7)
termWarn=$(tput setaf 3)
termError=${termBold}$(tput setaf 1)
termStep=$(tput setaf 4)

infoLabel="[${termInfo}Info${termPlain}] "
warningLabel="[${termWarn}Warn${termPlain}] "
errorLabel="[${termError}Error${termPlain}] "
stepLabel="[${termStep}Step${termPlain}] "

infoHighlight=$termBold
infoStrong=$termHighlight

function info {
    local messageAttrs
    while [[ "$1" =~ ^-([a-z])$ ]]; do
        case ${BASH_REMATCH[1]} in
            h)
                messageAttrs=$infoHighlight
                ;;
            s)
                # Strong
                messageAttrs=$infoStrong
                ;;
            *)
                echo "${infoLabel}[ Unknown switch $1 ]" >&2
                ;;
        esac
        shift
    done
    while test $# -gt 0; do
        echo "${infoLabel}${messageAttrs}$1${termPlain}"
        shift
    done
}

function warning {
    local prompt
    prompt=true
    while [[ "$1" =~ ^-([a-z])$ ]]; do
        case ${BASH_REMATCH[1]} in
            c)
                prompt=false
                ;;
            *)
                echo "${warningLabel}[ Unknown switch $1 ]" >&2
                ;;
        esac
        shift
    done
    while test $# -gt 0; do
        echo "${warningLabel}$1" >&2
        shift
    done
    if $prompt; then
        yesno "${warningLabel}Continue? (y/n) " || exit 1
    else
        true
    fi
}

function error {
    while test $# -gt 0; do
        echo "${errorLabel}$1" >&2
        shift
    done
    exit 1
}

function step {
    while test $# -gt 0; do
        echo "${stepLabel}$1"
        shift
    done
    if [ "$stepwiseSetup" = "yes" ]; then
        yesno "Proceed? (y/n) "
    else
        true
    fi
}

function yesno {
    local answer
    while [[ ! "$answer" =~ ^(y|yes|n|no)$ ]]; do
        [ -n "$answer" ] && warning "Valid answers are: yes y no n"
        read -p "$*" answer
        answer=$(tr '[:upper:]' '[:lower:]' <<<"$answer")
    done
    [[ $answer =~ ^(y|yes)$ ]]
}
