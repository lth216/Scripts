#!/bin/bash
set -eou pipefail

command_exist() {
    command -v $@ > /dev/null 2>&1
}

do_install() {
    if command_exist jenkins; then
        echo "[Warning] Jenkins is already installed on this machine"
        exit
    fi
    if [[ $USER != "root" ]]; then
        if ! command_exist sudo; then
            cat <<- EOF
            [Error]: This job requires root privilege.
            However, neither "sudo" nor "su" is available to perform this job.
EOF
            exit
        fi
    fi
    sudo apt install openjdk-11-jdk -y
    wget -p -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sudo bash -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA
    sudo apt-get update
    apt install jenkins -y
    systemctl start jenkins
    systemctl enable jenkins
    sudo ufw allow 8080
}

#---Main
do_install