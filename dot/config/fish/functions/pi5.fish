function pi5 --description 'alias pi5=ssh -t pi5.local tmux new -A -s pi5'
    ssh -t pi5.local tmux new -A -s pi5 $argv
end
