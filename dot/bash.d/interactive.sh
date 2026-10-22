# -*- mode: shell-script -*-

### Bash behaviour

## Options

shopt -s dotglob extglob
shopt -s no_empty_cmd_completion
shopt -s checkwinsize
#set +o ignoreeof # exit on EOF

# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache.
shopt -s cdspell

# Don't wait for job termination notification.
# set -o notify

# Don't use ^D to exit
# set -o ignoreeof

# Use case-insensitive filename globbing.
# shopt -s nocaseglob

if [[ $BASH_VERSION > "4" ]]; then
    shopt -s dirspell
    shopt -s globstar
    shopt -s checkjobs
fi

## History settings.

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=1000000

# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
# The '&' is a special pattern which suppresses duplicate entries.
export HISTIGNORE="history*:ls:cd[ ]*[.]*:[fb]g:exit:[ ]*"

shopt -s cmdhist

# Append rather than overwrite the history on disk.
shopt -s histappend

# Whenever displaying the prompt, write the previous line to disk
# export PROMPT_COMMAND="history -a"


## Completion (should be done before defining aliases)

load /etc/profile.d/bash-completion # Gentoo
load /etc/bash_completion # Debian
load /opt/local/etc/bash_completion # MacPorts


### Programs

## Keychain

if optcmd keychain --quiet; then
    load ~/.keychain/$HOSTNAME-sh
    load ~/.keychain/$HOSTNAME-sh-gpg
fi

if [ -e ~/.bash.d/bash-preexec.sh ]; then
    source ~/.bash.d/bash-preexec.sh
fi

### Auxilliary defs

TERM_RESET="\[\033[0m\]"
TERM_BOLD="\[\033[1m\]"
TERM_BOLD_OFF="\[\033[22m\]"
TERM_ITALICS="\[\033[3m\]"
TERM_ITALICS_OFF="\[\033[23m\]"
TERM_UNDERLINE="\[\033[4m\]"
TERM_UNDERLINE_OFF="\[\033[24m\]"
TERM_STRIKETHROUGH="\[\033[9m\]"
TERM_STRIKETHROUGH_OFF="\[\033[29m\]"
TERM_REDBG="\[\033[41m\]"
TERM_GREENBG="\[\033[42m\]"
TERM_BLUEBG="\[\033[44m\]"
TERM_CYANBG="\[\033[46m\]"
TERM_REDFG="\[\033[31m\]"
TERM_WHITEBG="\[\033[47m\]"
TERM_WHITEFG="\[\033[37m\]"
TERM_BLACKFG="\[\033[30m\]"
TERM_BLACKBG="\[\033[40m\]"


### Specific initialisation

load ~/.bash.d/os/$PLATFORM
load ~/.bash.d/host/${HOSTNAME%%.*}


### Prompt

jobcount () {
    jobs | wc -l | tr -d " "
}

case $TERM in
    xterm*|rxvt*|*linux|screen|gnome)
        PS1="${HOSTCOLOR:-${TERM_WHITEBG}${TERM_BLACKFG}} \h ${TERM_RESET} \$(jobcount) \w\n> "
        PS2="${TERM_REDFG}${TERM_BLACKBG}-${TERM_RESET}>"
        ;;
    *)
        PS1="\h \$(jobcount) \w\n> "
        PS2="->"
        ;;
esac
