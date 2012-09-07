source ~/.dotfiles/bin/lib/colors.sh

termInfo=$(tput setaf 7)
termStrong=$(tput setaf 7)
termWarn=$(tput setaf 3)
termError=${termBold}$(tput setaf 1)
termStep=$(tput setaf 4)

infoLabel="[${termInfo}Info${termPlain}] "
warningLabel="[${termWarn}Warn${termPlain}] "
errorLabel="[${termError}Error${termPlain}] "
stepLabel="[${termStep}Step${termPlain}] "

function info {
    while [[ "$1" =~ ^-([a-z])$ ]]; do
        case ${BASH_REMATCH[1]} in
            h)
                messageAttrs=$termBold
                ;;
            s)
                # Strong
                messageAttrs=$termStrong
                ;;
            *)
                echo "${infoLabel}[ Unknown info switch $1 ]" >&2
                ;;
        esac
        shift
    done
    while test $# -gt 0; do
        echo "${infoLabel}${messageAttrs}"$1"${termPlain}"
        shift
    done
}

function warning {
    local prompt
    prompt=true
    while [[ "$1" =~ ^-([a-z])$ ]]; do
        echo "got $1"
        case ${BASH_REMATCH[1]} in
            c)
                prompt=false
                ;;
            *)
                echo "${warningLabel}[ Unknown warning switch $1 ]" >&2
                ;;
        esac
        shift
    done
    while test $# -gt 0; do
        echo "${warningLabel}$1" >&2
        shift
    done
    $prompt && yesno "${warningLabel}Continue? (y/n) " || exit 1
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
