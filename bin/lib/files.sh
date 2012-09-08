function realdir {
    local dir
    dir=$(dirname "$1")
    if pushd "$dir" > /dev/null; then
        pwd
        popd > /dev/null
    else
        echo "$dir"
    fi
}

function realpath {
    echo $(realdir "$1")/$(basename "$1")
}

function available {
    which "$1" > /dev/null
}
