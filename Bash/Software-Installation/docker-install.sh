#!/bin/bash
set -eou pipefail

command_exist() {
    command -v $@ > /dev/null 2>&1
}

do_install() {
    if command_exist docker; then
        echo "[Warning] Docker tool is already available on this machine"
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
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    sudo tee /etc/docker/daemon.json <<-EOF
    {
        "exec-opts": ["native.cgroupdriver=systemd"],
        "log-driver": "json-file",
        "log-opts": {
            "max-size": "100m"
        },
        "storage-driver": "overlay2"
    }
EOF
    sudo systemctl daemon-reload 
    sudo systemctl restart docker
    sudo systemctl enable docker
}

#----Main
do_install