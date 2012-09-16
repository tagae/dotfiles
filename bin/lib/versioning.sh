if [ -n "$DOTFILES_LIB_VERSIONING" ]; then
    return
else
    DOTFILES_LIB_VERSIONING=true
fi

source ~/.dotfiles/bin/lib/interaction.sh

function flatVersionNumber {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d", $1,$2,$3,$4); }';
}

function majorVersionNumber {
    echo "$@" | awk -F. '{ print $1 }';
}

function minorVersionNumber {
    echo "$@.0" | awk -F. '{ print $2 }';
}

function revisionNumber {
    echo "$@.0.0" | awk -F. '{ print $3 }';
}

function checkBash {
    testedBashVersion=$1
    if [ -n "$BASH_VERSION" ]; then
        info "Running on bash $BASH_VERSION"
        [ -z "$testedBashVersion" ] && error "Bash setup not tested yet"
        bashFlatVersion=$(flatVersionNumber $BASH_VERSION)
        if [ "$bashFlatVersion" -lt $(flatVersionNumber $testedBashVersion) ]; then
            error "Bash is too old (expected ${testedBashVersion}+)"
        fi
    else
        error "Not running under bash"
    fi
}
