source ~/.dotfiles/bin/lib/colors.sh

termInfo=$(tput setaf 7)
termInfoSection=$(tput setaf 7)
termWarn=$(tput setaf 3)
termError=${termBold}$(tput setaf 1)
termStep=$(tput setaf 4)

function info {
    local messageAttrs
    while [[ $1 =~ -([a-z]) ]]; do
        case ${BASH_REMATCH[1]} in
            h)
                messageAttrs=$termBold
                ;;
            s)
                messageAttrs=$termInfoSection
                ;;
            *)
                warning "Unknown info switch $1."
                ;;
        esac
        shift
    done
    while test $# -gt 0; do
        echo "[${termInfo}Info${termPlain}] ${messageAttrs}"$1"${termPlain}"
        shift
    done
}

function warning {
    warningPrompt="[${termWarn}Warn${termPlain}] "
    while test $# -gt 0; do
        echo "${warningPrompt}$1" >&2
        shift
    done
    yesno "${warningPrompt}Continue? (y/n) " || exit 1
}

function error {
    while test $# -gt 0; do
        echo "[${termError}Error${termPlain}] "$1 >&2
        shift
    done
    exit 1
}

function step {
    while test $# -gt 0; do
        echo "[${termStep}Step${termPlain}] "$1
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
