# To sidestep aliases, prefix the command with \
# For example \rm will call the real 'rm' rather than the alias.

## Command customisations
alias bc='bc -l'
alias debfoster='sudo debfoster -v'
alias less='less -r' # raw control characters
alias whence='type -a' # where, of a sort
#alias screen="screen -U"

# Use interaction for destructive operations.
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Default to human-readable figures.
alias df='df -h'
alias du='du -h'
alias ls='ls -h'

# Directory listing.
alias l='ls -lh'
alias ll='ls -lah'

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
