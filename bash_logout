#!/bin/sh

source ~/.bash.d/optcmd

# invalidate sudoing capability
optcmd sudo -K

# when leaving the console clear the screen to increase privacy
clear
[ "$SHLVL" = 1 ] && optcmd clear_console -q
