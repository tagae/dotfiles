if [ -n "$DOTFILES_LIB_COLORS" ]; then
    return
else
    DOTFILES_LIB_COLORS=true
fi

# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/

function show-term-colors {
    for i in $(seq 1 7); do
        echo \
            "$(tput setaf $i)Text$(tput sgr0)" \
            "$(tput bold)$(tput setaf $i)Text$(tput sgr0)" \
            "$(tput sgr 0 1)$(tput setaf $i)Text$(tput sgr0)" \
            "\$(tput setaf $i)"
    done
}

termUnderline=$(tput sgr 0 1)
termBold=$(tput bold)
termStrong=$(tput smso)
termPlain=$(tput sgr0)$(tput rmso)
