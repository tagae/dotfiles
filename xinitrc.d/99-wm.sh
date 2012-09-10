OS=$(uname)
WM=~/.xinitrc.d/$OS/wm.sh

if [ -r $WM ]; then
    source $WM
else
    echo "Didn't find $WM" >&2
    exit 1
fi
