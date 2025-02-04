function fish_greeting
    set term (string lower -- $TERM)

    switch $term
        case '*kitty*' #kitty
            colorscript random
        case 'foot' #foot
            fastfetch -c ~/.config/fastfetch/minimal_foot.jsonc
        case '*xterm-256*' #foot with xterm-256
            fastfetch -c ~/.config/fastfetch/minimal_foot.jsonc
        case '*screen-256*' #tmux
            fastfetch -c ~/.config/fastfetch/arch.jsonc
        case '*ghostty*' #ghostty
            colorscript random
        case '*' #any other term
            fastfetch -c ~/.config/fastfetch/arch.jsonc  # Default behavior
    end
end
