# Common shell initialisation for bash and zsh on the Darwin platform

### Development

# test -x "$(which xcode-select)" && \
#     appendpath PATH $(xcode-select --print-path)/usr/bin

### Program configuration

## MacPorts
prependpath PATH /opt/local/bin /opt/local/sbin /opt/X11/bin
addflag CPPFLAGS -I /opt/local/include
addflag LDFLAGS -L /opt/local/lib
prependpath CPATH /opt/local/include
prependpath MANPATH /opt/local/share/man
prependpath INFOPATH /opt/local/share/info

## Fink
load /sw/bin/init.sh # do most of the necessary setup
addflag CPPFLAGS -I /sw/include
addflag LDFLAGS -L /sw/lib
addflag ACLOCAL_FLAGS -I /sw/share/aclocal
prependpath PKG_CONFIG_PATH /sw/lib/pkgconfig

## Python

appendpath PATH /opt/local/Library/Frameworks/Python.framework/Versions/Current/bin

## Java

#export JAVA_HOME=`/usr/libexec/java_home`

export CATALINA_HOME="$HOME/Applications/opt/apache-tomcat"

### Aliases

alias cdrecord='cdrecord driveropts=burnfree -v dev=IODVDServices'
alias showhf='defaults write com.apple.Finder AppleShowAllFiles YES | killall Finder'
alias hidehf='defaults write com.apple.Finder AppleShowAllFiles NO | killall Finder'
if testcmd htop; then
    alias top='htop'
else
    alias top='top -o cpu'
fi
alias la='ls -laO'
alias Emacs='open -a Emacs'
alias o='open'

### Colors

export CLICOLOR="true"
export LSCOLORS="bxfxcxdxcxegedabagacad"

### Environment

prefcmd BROWSER open

# Set MacOS PATH setting from current environment.
# if [ -x /usr/libexec/path_helper ]; then
#     eval `/usr/libexec/path_helper -s`
#     defaults write $HOME/.MacOSX/environment PATH "$PATH"
# fi
