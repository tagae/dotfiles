### i18n

# LC_ALL is unset since it overwrites everything.
unset LC_ALL
#export LC_ALL="en_DK.UTF-8"

# European-oriented English locale.
export LANG="en_DK.UTF-8"
#export LANG="en_US.UTF-8"

# Never translate program output.
export LC_MESSAGES="C"

# Use ISO dates.
export LC_TIME="en_DK.UTF-8"

# if ps -ef | grep -e "^`whoami`\b.*[i]bus-daemon\b.*x" >/dev/null
# then
#     export XMODIFIERS="@im=ibus"
#     export GTK_IM_MODULE="ibus"
#     export QT_IM_MODULE="ibus"
#     export QT4_IM_MODULE="ibus"
# fi

# Let apps see <Multi_key> for character composition.
# (http://article.gmane.org/gmane.emacs.devel/170858)
export XMODIFIERS="@im=none"
#export GTK_IM_MODULE="xim"
#export QT_IM_MODULE="xim"
#export QT4_IM_MODULE="xim"

#export XMODIFIERS="@im=ibus"
export GTK_IM_MODULE="ibus"
export QT_IM_MODULE="ibus"
export QT4_IM_MODULE="ibus"

### Environment

# try in order (last is preferred)
prefcmd BROWSER elinks
prefcmd BROWSER konqueror
#prefcmd BROWSER "konqueror '%s' &"


### Program configuration

## Alsa
export ALSA_OUTPUT_PORTS="Emu10k1 WaveTable:0"

## gnome-terminal

[ -r /etc/profile.d/vte.sh ] && source /etc/profile.d/vte.sh

## Java
export JAVA6_HOME="/opt/icedtea-bin-6.1.13.7"

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

alias ls='ls -hF --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lha --color=auto'

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias grep='grep --color=auto'
alias cgrep='grep --color=always'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias free='free -m'

alias cdrecord='cdrecord driveropts=burnfree -v dev=/dev/hdc'
alias mkisofs='mkisofs -iso-level 4 -r'

alias madplay='madplay -v --fade-in --tty-control'
#alias eclipse='GTK2_RC_FILES=/usr/share/themes/Default/gtk-2.0/gtkrc eclipse-bin-4.2'

alias suspend='sudo pm-suspend'
