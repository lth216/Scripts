#!/bin/bash
set -eou pipefail

<<-comment
Description: This script is to delete all the files, especially logs older than 24 hours ago since they last modified
Explaination:
    - Get time length from Epoch to 24 hours ago (time threshold)
    - Get time length from Epoch to last modification time of a file (file time)
    - (file time < time threshold) --> file is older than 24 hours ago --> Remove 
comment

WORK_DIR=$(cd $(dirname $0) && pwd)
TIME_THRESHOLD=$(date -d "24 hours ago" +%s) #Get time length from Epoch to 24 hours ago

get_cmd_args() {
    options=$(getopt -o hd: -l help,directory: -- "$@")
    eval set -- $options
    while :; do
        case $1 in
            -h|--help)
                usage
                exit
                ;;
            -d|--directory)
                DIRECTORY=$2
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

main() {
    TARGET_DIR=${DIRECTORY:-$WORK_DIR}
    find $TARGET_DIR -type f -mmin +1440 -print | while read -d $'\n' file; do
        FILE_TIME=$(stat -c %Y $file) #Get time length from Epoch to last modification time of file
        if [[ $FILE_TIME -lt $TIME_THRESHOLD ]]; then
            echo "Remove file: $file"
            rm $file
        fi
    done
}

#---Main
get_cmd_args $@
main
