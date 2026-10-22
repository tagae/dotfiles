# Go.

# Homebrew's Go keeps its standard library in libexec.
set -q HOMEBREW_PREFIX
and test -d $HOMEBREW_PREFIX/opt/go/libexec
and set -x GOROOT $HOMEBREW_PREFIX/opt/go/libexec

command -sq go
and set -x GOPATH $HOME/Applications/opt/go
and fish_add_path --path --append $GOPATH/bin
