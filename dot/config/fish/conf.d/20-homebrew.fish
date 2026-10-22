# Homebrew, and the GNU tools that it provides in place of the BSD ones that macOS ships.
#
# Files that look for commands installed by Homebrew must sort after this one.

test -x /opt/homebrew/bin/brew
or return

/opt/homebrew/bin/brew shellenv | source

set -l homebrew $HOMEBREW_PREFIX/opt

# Each --move puts its directory first, so the last one listed ends up with the highest precedence.
for dir in \
        git/bin \
        coreutils/libexec/gnubin \
        findutils/libexec/gnubin \
        gnu-sed/libexec/gnubin \
        gpatch/libexec/gnubin \
        make/libexec/gnubin \
        m4/bin \
        bison/bin \
        gpatch/bin \
        gawk/libexec/gnubin
    fish_add_path --path --move $homebrew/$dir
end

test -d $homebrew/bison/lib
and set -gx LDFLAGS -L$homebrew/bison/lib

test -d $homebrew/libiconv/lib
and set -gx LDFLAGS -L$homebrew/libiconv/lib $LDFLAGS
and set -gx CPPFLAGS -I$homebrew/libiconv/include $CPPFLAGS
