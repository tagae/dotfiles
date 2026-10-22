source ~/.bin/lib/files.sh

# Guest setup
if available VBoxClient && [ -n "$(lsmod | grep vboxguest)" ]; then
    # Automatic resize, clipboard and seamless mode in VirtualBox
    VBoxClient --display
    VBoxClient --clipboard
    VBoxClient --seamless
fi
