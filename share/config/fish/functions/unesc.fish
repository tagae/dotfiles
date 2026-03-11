function unesc --description "Replace escaped newlines by actual newlines"
    cat | string replace --all --filter '\n' \n
end
