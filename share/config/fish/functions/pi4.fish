function pi4 --description 'alias pi4=ssh -t pi4.local tmux new -A -s pi4'
    ssh -t pi4.local tmux new -A -s pi4 $argv
end
