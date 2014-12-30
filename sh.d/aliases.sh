## Command customisations
alias l='ls -lh'
alias ll='ls -lah'
alias ls='ls -G'
alias df='df -h'
alias rm='rm -i'
alias cp='cp -i'
alias du='du -h'
alias bc='bc -l'
alias debfoster='sudo debfoster -v'
#alias screen="screen -U"

## Silence cdspell and $CDPATH echo
function cd () {
    builtin cd "$@" 1> /dev/null
}

## New commands

alias edit=$EDITOR
alias e=$EDITOR

## Fast directory change
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

## Remove cruft
alias rmold='rm -vf .*~ *~ \#*\#'
alias rmtex='rm -vf .*~ *~ *log *.nav *.snm *.toc  *.cp *.fn *.tp *.vr *.pg *.ky \#* *blg *ilg *.dvi *.aux'
alias rmcruft='find . -name .DS_Store -type f -delete'
