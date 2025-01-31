function code --wraps=vscodium --description 'alias code=vscodium'
    if type -f vscodium &>/dev/null
        uwsm app -- codium $argv
    else
        missing_package vscodium
    end
end