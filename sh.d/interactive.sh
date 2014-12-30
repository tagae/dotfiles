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

### Platform-Specific configuration

load ~/.sh.d/os/$(uname) # platform specific
load ~/.sh.d/host/${HOSTNAME%%.*} # host specific

### User-specific configuration

## Paths
prependpath PATH $HOME/.bin
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
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'

## files
#FIGNORE="~:.pyc:.swp:.swa:.git" # things to ignore during tab completion

## grc
testcmd brew && load "`brew --prefix grc`/etc/grc.bashrc"

## keychain (SSH, PGP)
eval $(optcmd keychain --eval --quiet)

## GnuPG

# See gpg-agent(1)
GPG_TTY=$(tty)
export GPG_TTY

## OpenSSL
setpath OPENSSL_CONF $HOME/.ssl/openssl.cnf

## Java
export CLASSPATH=""
prependpath CLASSPATH /opt/local/share/java/saxon9he.jar
prependpath CLASSPATH /sw/share/java/saxon-b/saxon8.jar
export M2_HOME="$HOME/Applications/opt/apache-maven-3.2.3"
export M2="$M2_HOME/bin"
prependpath PATH "$M2"

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

### Heroku
prependpath PATH /usr/local/heroku/bin

### Ruby
prependpath PATH "$HOME/.gem/ruby/1.9.1/bin"

### Python
#prependpath WORKON_HOME "$HOME/.virtualenvs"
#load "$HOME/Library/Python/3.3/bin/virtualenvwrapper.sh"
#prependpath PATH "$HOME/Library/Python/3.3/bin"
