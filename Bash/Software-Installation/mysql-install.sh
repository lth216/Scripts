#!/bin/bash
set -eou pipefail

#Global vars
DEFAULT_VERSION="0.8.29-1"
LSB_DIST=$(cat /etc/lsb-release | grep "DISTRIB_ID" | awk -F '=' '{print tolower($2)}')
WORK_DIR=$(cd $(dirname $0) && pwd)

usage() {
    cat <<- EOF
    Usage: ./mysql-install.sh (Default version: MYSQL 0.8.29-1)
    Options:
        -v, --version: Specify the version of MySQL server
EOF
}

command_exist() {
    command -v $@ > /dev/null 2>&1
}

get_cmd_args() {
    options=$(getopt -o hv: -l help,version: -- "$@")
    eval set -- $options
    while :; do
        case $1 in
            -h|--help)
                usage
                exit
                ;;
            -v|--version)
                VERSION=$2
                shift 2
                ;;
            --)
                shift 1
                break
                ;;
            *)
                echo "Invalid argument"
                exit
                ;;
        esac
    done
}

do_install() {
    if command_exist mysql; then
        echo "[Warning] MySQL is already installed on this machine"
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
    case $LSB_DIST in
        ubuntu)
            DIST_VERSION=$(cat /etc/lsb-release | grep "DISTRIB_CODENAME" | awk -F '=' '{print $2}')
            DOWNLOAD_MIRROR="https://repo.mysql.com/apt/ubuntu/dists"
            TARGET_VERSION=${VERSION:-$DEFAULT_VERSION}
            BINARY_FILE="mysql.deb"
            curl -fs "https://repo.mysql.com/apt/ubuntu/pool/mysql-apt-config/m/mysql-apt-config/mysql-apt-config_${TARGET_VERSION}_all.deb" -o ${WORK_DIR}/${BINARY_FILE}
            if [[ ! -f ${WORK_DIR}/${BINARY_FILE} ]]; then
			    echo "Cannot download binary file from MySQL website"
                echo "Plese specify proper version or check the Internet connection"
			    exit
		    fi
            sudo dpkg -i ${WORK_DIR}/${BINARY_FILE}
            sudo apt-get update
            sudo apt-get install -y mysql-server
            rm ${WORK_DIR}/${BINARY_FILE} || True
            ;;
        *)
            echo "Unsupport Linux distribution"
            exit 
            ;;
    esac
}

#---Main
get_cmd_args $@
do_install