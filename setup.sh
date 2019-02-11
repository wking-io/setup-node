#!/bin/bash

declare -r GITHUB_REPOSITORY="wking-io/setup-node"

declare -r SETUP_ORIGIN="git@github.com:$GITHUB_REPOSITORY.git"
declare -r SETUP_TARBALL_URL="https://github.com/$GITHUB_REPOSITORY/tarball/master"
declare -r SETUP_UTILS_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/master/src/os/utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

declare setupDirectory="$HOME/.setup-node"
declare skipQuestions=false

# ----------------------------------------------------------------------
# | Helper Functions                                                   |
# ----------------------------------------------------------------------

download() {

    local url="$1"
    local output="$2"

    if command -v "curl" &> /dev/null; then

        curl -LsSo "$output" "$url" &> /dev/null
        #     │││└─ write output to file
        #     ││└─ show error messages
        #     │└─ don't show the progress meter
        #     └─ follow redirects

        return $?

    elif command -v "wget" &> /dev/null; then

        wget -qO "$output" "$url" &> /dev/null
        #     │└─ write output to file
        #     └─ don't show output

        return $?
    fi

    return 1

}

download_setup() {

    local tmpFile=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    print_in_purple "\n • Download and extract archive\n\n"

    tmpFile="$(mktemp /tmp/XXXXX)"

    download "$SETUP_TARBALL_URL" "$tmpFile"
    print_result $? "Download archive" "true"
    printf "\n"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ! $skipQuestions; then

        ask_for_confirmation "Do you want to store the setup in '$setupDirectory'?"

        if ! answer_is_yes; then
            setupDirectory=""
            while [ -z "$setupDirectory" ]; do
                ask "Please specify another location for the setup (path): "
                setupDirectory="$(get_answer)"
            done
        fi

        # Ensure the `dotfiles` directory is available

        while [ -e "$setupDirectory" ]; do
            ask_for_confirmation "'$setupDirectory' already exists, do you want to overwrite it?"
            if answer_is_yes; then
                rm -rf "$setupDirectory"
                break
            else
                setupDirectory=""
                while [ -z "$setupDirectory" ]; do
                    ask "Please specify another location for the setup (path): "
                    setupDirectory="$(get_answer)"
                done
            fi
        done

        printf "\n"

    else

        rm -rf "$setupDirectory" &> /dev/null

    fi

    mkdir -p "$setupDirectory"
    print_result $? "Create '$setupDirectory'" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Extract archive in the `setup` directory.

    extract "$tmpFile" "$setupDirectory"
    print_result $? "Extract archive" "true"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    rm -rf "$tmpFile"
    print_result $? "Remove archive"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    return 1

}

download_utils() {

    local tmpFile=""

    tmpFile="$(mktemp /tmp/XXXXX)"

    download "$SETUP_UTILS_URL" "$tmpFile" \
        && . "$tmpFile" \
        && rm -rf "$tmpFile" \
        && return 0

   return 1

}

extract() {

    local archive="$1"
    local outputDir="$2"

    if command -v "tar" &> /dev/null; then
        tar -zxf "$archive" --strip-components 1 -C "$outputDir"
        return $?
    fi

    return 1

}

verify_os() {

    declare -r MINIMUM_MACOS_VERSION="10.10"

    local os_name=""
    local os_version=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if the OS is `macOS` and
    # it's above the required version.

    os_name="$(uname -s)"

    if [ "$os_name" == "Darwin" ]; then

        os_version="$(sw_vers -productVersion)"

        if is_supported_version "$os_version" "$MINIMUM_MACOS_VERSION"; then
            return 0
        else
            printf "Sorry, this script is intended only for macOS %s+" "$MINIMUM_MACOS_VERSION"
        fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    else
        printf "Sorry, this script is intended only for macOS!"
    fi

    return 1

}



# ----------------------------------------------------------------------
# | Main                                                               |
# ----------------------------------------------------------------------

main() {

    # Ensure that the following actions
    # are made relative to this file's path.

    cd "$(dirname "${BASH_SOURCE[0]}")" \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Load utils

    if [ -x "utils.sh" ]; then
        . "utils.sh" || exit 1
    else
        download_utils || exit 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Ensure the OS is supported and
    # it's above the required version.

    verify_os \
        || exit 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    skip_questions "$@" \
        && skipQuestions=true

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ask_for_sudo

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if this script was run directly (./<path>/setup.sh),
    # and if not, it most likely means that the setup was not
    # yet set up, and they will need to be downloaded.

    printf "%s" "${BASH_SOURCE[0]}" | grep "setup.sh" &> /dev/null \
        || download_setup

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ./local.sh   

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ./homebrew.sh

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ./nvm.sh

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ./npm.sh

}

main