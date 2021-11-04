### i18n

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
# export LC_CTYPE="en_GB.UTF-8"
# export LANGUAGE="en_GB"

### Local host configuration

prependpath PATH /sbin /usr/sbin /usr/local/bin /usr/local/sbin
prependpath MANPATH /usr/local/share/man /usr/share/man
prependpath INFOPATH /usr/local/share/info /usr/share/info

prependpath INFOPATH $HOME/Applications/share/info

# System paths
MANPATH="$MANPATH:"

# Security
umask 077 # neither group nor others have any perms


### Platform-Specific configuration

load ~/.sh.d/os/$(uname) # platform specific
load ~/.sh.d/host/${HOSTNAME%%.*} # host specific

### User-specific configuration

## Paths
prependpath PATH $HOME/.bin $HOME/.local/bin
prependpath PATH $HOME/Applications/bin
prependpath CDPATH $HOME/Work
export CDPATH

## Documentation
prependpath MANPATH $HOME/Applications/share/man
prependpath INFOPATH $HOME/Applications/share/info

## Environment
export MAIL='Sebastián González <tagae@ehub.io>'
export EMAIL=$MAIL
prefcmd PAGER less
prefcmd MANPAGER less
prefcmd LISTER ls
# prefcmd MANPAGER less -+$LESS -iRSw
export EDITOR='emacsclient -c'
export VISUAL="$EDITOR"
export ALTERNATE_EDITOR='emacs'
#prefcmd EDITOR ~/Applications/bin/edit
#prefcmd VISUAL ~/Applications/bin/edit
#prefcmd ALTERNATE_EDITOR emacs

## Aliases
load ~/.sh.d/aliases


### Tool configuration

## kinit
prependpath PATH /usr/local/Cellar/krb5/*/bin

## coreutils
prependpath PATH /usr/local/opt/coreutils/libexec/gnubin

## C-like compilers and linkers
addflag CFLAGS -I $HOME/include
addflag CPPFLAGS -I $HOME/Applications/include
addflag LDFLAGS -L $HOME/lib
addflag LDFLAGS -L $HOME/Applications/lib
prependpath LD_LIBRARY_PATH $HOME/lib

## less
export LESSHISTFILE="-"
# export LESS="FiRSwX"

## grep
#export GREP_OPTIONS='--color=auto' # deprecated
#export GREP_COLOR='1;32'

## files
#FIGNORE="~:.pyc:.swp:.swa:.git" # things to ignore during tab completion

## grc
testcmd brew && load "`brew --prefix grc`/etc/grc.bashrc"

## git

# If available, use git's contrib/completion/git-prompt.sh
# It must be enabled explicitly for bash or zsh; check the source for info.
# TODO: check the source code and improve my own prompt
# load ~/.sh.d/lib/git-prompt.sh
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=auto
GIT_PS1_SHOWCOLORHINTS=true
GIT_PS1_HIDE_IF_PWD_IGNORED=true

## keychain (SSH, PGP)
#[ -z "$GPG_AGENT_INFO" ] && eval $(optcmd keychain --eval --agents gpg --quick --quiet)
#[ -z "$SSH_AUTH_SOCK" ] && eval $(optcmd keychain --eval --agents ssh --quick --quiet)

## GnuPG

# See gpg-agent(1)
GPG_TTY=$(tty)
export GPG_TTY

## OpenSSL
setpath OPENSSL_CONF $HOME/.ssl/openssl.cnf

## Kerberos
export KRB5_CONFIG=$HOME/.krb5.conf

## Java
export CLASSPATH=""
prependpath CLASSPATH /opt/local/share/java/saxon9he.jar
prependpath CLASSPATH /sw/share/java/saxon-b/saxon8.jar

## Maven
export MAVEN_OPTS="-Dfile.encoding=UTF-8 -Xms1024m -Xmx3072m -Dmaven.surefire.debug=-Xmx3072m"

## Autoconf
setpath CONFIG_SITE $HOME/.autoconf

## ASDF
setpath PRIVATE_ASDF_INSTALL_DIR ~/.asdf-install-dir/

## Midnight Commander chdir enhancement
# (allow mc to chdir to its latest working dir at exit)
load /usr/share/mc/mc.gentoo

## OpemMCL
setpath CCL_DEFAULT_DIRECTORY $HOME/Applications/opt/ccl-svn

## jsdoc
export JSDOCDIR="$HOME/Applications/opt/jsdoc-toolkit"
export JSDOCTEMPLATEDIR="$JSDOCDIR/templates/jsdoc"

## node.js
prependpath PATH "$HOME/.npm/bin" # see ~/.npmrc
export PATH="node_modules/.bin:$PATH" # locally installed commands

## Slime
prependpath INFOPATH $HOME/Applications/lib/lisp/slime/doc

## cabal (Haskell package system)
prependpath PATH $HOME/.cabal/bin
prependpath MANPATH $HOME/.cabal/share/man

## ClojureScript
export CLOJURESCRIPT_HOME=$HOME/Applications/opt/clojurescript

## Heroku
prependpath PATH /usr/local/heroku/bin

## Ruby
# Use the last (most recent) available version
if [ -d "$HOME"/.gem/ruby/ ]; then
    ruby_paths=("$HOME"/.gem/ruby/*/bin)
    if (( ${#ruby_paths} > 0 )); then
       prependpath PATH "${ruby_paths[-1]}"
    fi
fi
# See https://github.com/rbenv/rbenv#installation
prependpath PATH "$HOME"/.rbenv/bin
if command -v rbenv > /dev/null; then
    eval "$(rbenv init -)"
fi

## pyenv
export PYENV_ROOT=/usr/local/var/pyenv
if command -v pyenv > /dev/null; then
    eval "$(pyenv init -)"
fi

## Go
export GOPATH=$HOME/Applications/share/go
prependpath PATH "$GOPATH/bin"

## Haskell
prependpath PATH "$HOME/.cabal/bin"

## SDKMAN
load $HOME/.sdkman/bin/sdkman-init.sh

## AWS
export EC2_HOME="$HOME"/Applications/opt/ec2-api-tools
prependpath PATH "$EC2_HOME/bin"
if [ -f $HOME/.aws/credentials ]; then
    export AWS_ACCESS_KEY="$(awk '/aws_access_key_id/ {print $3}' $HOME/.aws/credentials)"
    export AWS_SECRET_KEY="$(awk '/aws_secret_access_key/ {print $3}' $HOME/.aws/credentials)"
fi
export EC2_URL=https://ec2.eu-west-1.amazonaws.com

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
