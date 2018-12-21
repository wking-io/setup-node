# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Load utils

    if [ -x "utils.sh" ]; then
        . "utils.sh" || exit 1
    else
        printf "Utils were not found..."
        exit 1
    fi
    
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

./homebrew.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

./nvm.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

./npm.sh