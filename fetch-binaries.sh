#!/bin/bash
# Fetches OC client and/or oc installer binary

# Initializing variables, change these as required
MIRROR=mirror.openshift.com/pub/openshift-v4/clients

# Asks for which binaries to fetch and for which OCP version. Runs again if user selects something other than 1-3.
function main {
    while true; do
        # This read prints each option in a new line.
        read -rep $'Which do you want to install?\n1. OC client\n2. OC installer\n3. Both\n' ANSWER
        read -rep $'Where do you want to place the binary? [Default: /usr/local/bin]\n' BIN_PATH
        BIN_PATH=${BIN_PATH:-/usr/local/bin}
        read -rep $'What version do you want to install? (E.g 4.12.2)\n' OCP_VERSION
        case $ANSWER in
          [1]* ) oc_client; break;;
          [2]* ) oc_installer; break;;
          [3]* ) oc_client; oc_installer; break;;
          * ) echo "Please answer 1, 2 or 3.";;
        esac
    done
}



# Gets the openshift-install binary and puts it in the defined path of $BIN_PATH
function oc_installer {
    wget -q --show-progress https://${MIRROR}/ocp/${OCP_VERSION}/openshift-install-linux-${OCP_VERSION}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Could not reach mirror, try again"
        exit
    fi
    printf "\nAttempting to extract to $BIN_PATH\n"
    tar zxvf openshift-install-linux-${OCP_VERSION}.tar.gz -C $BIN_PATH openshift-install >/dev/null
    rm -f openshift-install-linux-${OCP_VERSION}.tar.gz
    chmod +x $BIN_PATH/openshift-install
    printf "\nValidating installer...\n"
    validate_binary "timeout 5s $BIN_PATH/openshift-install version" "$OCP_VERSION" "OpenShift installer $OCP_VERSION successfully installed" "Could not verify installer in $BIN_PATH"
}

# Gets the oc binary and puts it in the defined path of $BIN_PATH
function oc_client {
    wget -q --show-progress https://${MIRROR}/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Could not reach mirror, try again"
        exit
    fi
    printf "\nAttempting to extract to $BIN_PATH\n"
    tar zxvf openshift-client-linux-${OCP_VERSION}.tar.gz -C $BIN_PATH oc kubectl >/dev/null
    rm -f openshift-client-linux-${OCP_VERSION}.tar.gz
    chmod +x $BIN_PATH/oc
    determine_shell
    printf "\nValidating client...\n"
    validate_binary "timeout 5s $BIN_PATH/oc version" "$OCP_VERSION" "OpenShift Client $OCP_VERSION successfully installed" "Could not verify client in $BIN_PATH"
}

function validate_binary {
    output=$(eval "$1")
    if [[ "$output" == *"$2"* ]]; then
    # We are doing the sed command here to insert four whitespaces to the output.
    # This is to increase the readability
        echo "$3"  | sed 's/^/    /'
    else
        echo "$4"  | sed 's/^/    /'
    fi
}

# Determining user shell for oc completion
function determine_shell {
    if [[ "$SHELL" =~ "bash" ]]; then
        printf "\nUsing bash, adding OC completion /etc/bash_completion.d/openshift\n"
        oc completion bash >/etc/bash_completion.d/openshift
    elif [[ "$SHELL" =~ "zsh" ]]; then
        printf "\nUsing zsh, adding OC completion to ~/.zshrc\n"
        if ! grep -q "source <(oc completion zsh)" ~/.zshrc; then
            echo "source <(oc completion zsh)" >> ~/.zshrc
        fi
    fi
}
main