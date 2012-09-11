### i18n

export LANG="en_GB.UTF-8"
export LC_CTYPE="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"
export LANGUAGE="en_GB"

### Local host configuration

prependpath PATH /sbin /usr/sbin /usr/local/bin
prependpath MANPATH /usr/local/share/man /usr/share/man
prependpath INFOPATH /usr/local/share/info /usr/share/info

# System paths
MANPATH="$MANPATH:"

### User-specific configuration

## Paths
prependpath PATH $HOME/.bin
prependpath PATH $HOME/Applications/bin
prependpath PATH $HOME/Applications/opt/npm/bin
prependpath CDPATH $HOME/Work/UCL
export CDPATH

## Development
addflag CFLAGS -I $HOME/include
addflag CPPFLAGS -I $HOME/Applications/include
addflag LDFLAGS -L $HOME/lib
addflag LDFLAGS -L $HOME/Applications/lib
prependpath LD_LIBRARY_PATH $HOME/lib

## Documentation
prependpath MANPATH $HOME/Applications/share/man
prependpath INFOPATH $HOME/Applications/share/info

## Environment
export MAIL='Sebastian Gonzalez <s.gonzalez@uclouvain.be>'
export EMAIL=$MAIL
prefcmd PAGER less
prefcmd MANPAGER less
# prefcmd MANPAGER less -+$LESS -iRSw
prefcmd LISTER ls
prefcmd EDITOR ~/Applications/bin/edit
prefcmd VISUAL ~/Applications/bin/edit
prefcmd ALTERNATE_EDITOR emacs
#~/Applications/bin/edit

### Tool configuration

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

## OpenSSL
setpath OPENSSL_CONF $HOME/.ssl/openssl.cnf

## Java
export CLASSPATH=""
prependpath CLASSPATH /opt/local/share/java/saxon9he.jar
prependpath CLASSPATH /sw/share/java/saxon-b/saxon8.jar

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
export JSDOCDIR=$HOME/Applications/opt/jsdoc-toolkit
export JSDOCTEMPLATEDIR=$JSDOCDIR/templates/jsdoc

## node.js
prependpath MANPATH $HOME/Applications/opt/npm/share/man

## Slime
prependpath INFOPATH $HOME/Applications/lib/lisp/slime/doc

## cabal (Haskell package system)
prependpath PATH $HOME/.cabal/bin
prependpath MANPATH $HOME/.cabal/share/man

## ClojureScript
export CLOJURESCRIPT_HOME=$HOME/Applications/opt/clojurescript

### Specific initialisation

load ~/.sh.d/aliases

load ~/.sh.d/os/${PLATFORM:=$(uname | tr "[:upper:]" "[:lower:]")} # platform specific
load ~/.sh.d/host/${HOSTNAME%%.*} # host specific
