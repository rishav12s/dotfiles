function fetch --wraps=fastfetch --description 'alias fetch=fastfetch --logo-type kitty'
    if type -f fastfetch &>/dev/null
        fastfetch --logo-type kitty $argv
    else
        missing_package fastfetch
    end
end