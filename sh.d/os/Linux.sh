### Tools

# try in order (last is preferred)
prefcmd BROWSER elinks
prefcmd BROWSER konqueror
#prefcmd BROWSER "konqueror '%s' &"

### Program configuration

## Alsa
export ALSA_OUTPUT_PORTS="Emu10k1 WaveTable:0"


### Colors

if [ -x /usr/bin/dircolors ]; then
    if [ -f ~/.dir_colors ]; then
        eval `dircolors -b ~/.dir_colors`
    else
        eval `dircolors -b`
    fi
fi

[ -n "$LS_COLORS" ] && LS_COLORS_SW='--color=auto'

### Aliases

alias ls='ls -F --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lha --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias free='free -m'
alias cdrecord='cdrecord driveropts=burnfree -v dev=/dev/hdc'
alias mkisofs='mkisofs -iso-level 4 -r'
alias madplay='madplay -v --fade-in --tty-control'
