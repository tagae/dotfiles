if false; then

xkbDir="$HOME/.xkb"

if [ -d $xkbDir/keymap ]; then
  setxkbmap -types $HOSTNAME -print | \
    sed -e '/xkb_symbols/s/"[[:space:]]/+'$HOSTNAME'&/' | \
    xkbcomp -I$xkbDir -R$xkbDir - $DISPLAY
fi

fi
