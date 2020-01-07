# Usage:
#
# SESSION=<session> startx
#
# where <session> is one of the files in the 'sessions' directory.

SESSION=~/.xinitrc.d/sessions/${SESSION:-openbox}.sh

if [ -r $SESSION ]; then
    source $SESSION
else
    echo "Could not find $SESSION" >&2
    exit 1
fi
