#!/bin/bash
set -eou pipefail

#Global vars
WORK_DIR="/tmp"
HARBOR_DIR="$WORK_DIR/harbor"
HARBOR_CONFIGURATION_FILE="harbor.yml"
HARBOR_REGISTRY_URL="registry.longtruong-lab.online"
USER_EMAIL="longth2162000@gmail.com"

command_exist() {
    command -v "$@" > /dev/null 2>&1
}

check_dependencies() {
    if [[ $USER != "root" ]]; then
        if ! command_exist sudo; then
            cat <<-EOF
            [Error]: This job requires root privilege.
            However, neither "sudo" nor "su" is available to perform this job.
EOF
        exit
        fi
    fi
    
    # Install certbot
    if ! command_exist certbot; then
    	sudo apt-get update
        sudo apt-get install -y certbot
    fi

    # Install harbor
    cd $WORK_DIR
    curl -fsSL https://api.github.com/repos/goharbor/harbor/releases/latest | grep browser_download_url | cut -d '\"' -f 4 | grep '.tgz$' | wget -i - > /dev/null 2>&1
    tar xvzf harbor-offline-installer*.tgz > /dev/null 2>&1
    
    # Check Docker tool
    if ! command_exist docker || ! command_exist docker-compose; then
            cat <<-EOF
            [Error]: This job requires Docker and Docker-compose tool to be installed on the machine.
            Please install Docker and Docker-compose first !!!
EOF
        exit
    fi
}

do_install() {
    check_dependencies
    # Get certificates by certbot
    AUTHENTICATION_FILE="certificate.log"
    if [[ ! -f $WORK_DIR/$AUTHENTICATION_FILE ]]; then
    	sudo certbot certonly --standalone -d $HARBOR_REGISTRY_URL --preferred-challenges http --agree-tos -m $USER_EMAIL --keep-until-expiring > $AUTHENTICATION_FILE 2>&1
    fi
    
    fullchain=$(cat $AUTHENTICATION_FILE | grep -i "fullchain.pem" | tr -d [:blank:] | cut -d ':' -f2)
    encrypted_fullchain=$(echo $fullchain | sed 's/\//\\\//g')
    privkey=$(cat $AUTHENTICATION_FILE | grep -i "privkey.pem" | tr -d [:blank:] | cut -d ':' -f2)
    encrypted_privkey=$(echo $privkey | sed 's/\//\\\//g')

    cd $HARBOR_DIR
    cp harbor.yml.tmpl $HARBOR_CONFIGURATION_FILE

    # Substitute value of yaml file
    sed -ri \"s/^(\s*)(hostname\s*:\s*(.+)\s*$)/\1hostname: $HARBOR_REGISTRY_URL/\" $HARBOR_CONFIGURATION_FILE
    sed -ri \"s/^(\s*)(certificate\s*:\s*(.+)\s*$)/\1certificate: $encrypted_fullchain/\" $HARBOR_CONFIGURATION_FILE
    sed -ri \"s/^(\s*)(private_key\s*:\s*(.+)\s*$)/\1private_key: $encrypted_privkey/\" $HARBOR_CONFIGURATION_FILE

    sudo bash prepare
    sudo bash install.sh
}

#---Main
do_install