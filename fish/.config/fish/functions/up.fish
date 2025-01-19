function up --wraps='yay -Syu' --description 'alias up=yay -Syu'
    # Update packages
    if type -f topgrade &>/dev/null
        topgrade -k --only system
    else if type -f yay &>/dev/null
        yay -Syu $argv | tee /tmp/update-log.txt
    else
        pacman -Syu $argv | tee /tmp/update-log.txt
    end

    # Check for kernel updates
    if grep -E 'upgraded (linux|linux-zen|linux-lts|linux-hardened)' /tmp/update-log.txt
        notify-send "Reboot Recommended" "Kernel updated. Please reboot to apply changes."
    end

    # Clean up
    rm -f /tmp/update-log.txt
end
