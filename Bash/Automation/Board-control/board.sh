#!/bin/bash
set -eo pipefail
[[ -n ${DEBUG:-} ]] && set -x

WORK_DIR=$(cd $(dirname $0) && pwd)
TIMELINE=$(TZ='Asia/Ho_Chi_Minh' date +'%Y%m%d')

# Board info
BOARD_NAME="whitehawk-150"
SERIAL_ID="pci-0000:00:14.0-usb-0:10:1.0-port0"
SERIAL_PORT=$(readlink -f /dev/serial/by-path/$SERIAL_ID)
BAUDRATE=921600
LOGIN_TOOL=miniterm

# V4H remote source
REMOTE_BOARD_DIR=/tftpboot/iccom
MODE_BOOT_DIR=$REMOTE_BOARD_DIR/ModeSettingTool
MODE_BURN_DIR=$REMOTE_BOARD_DIR/UpdateFirmwareTool
IPL_DIR=$REMOTE_BOARD_DIR/ipl

# List of available boards
LIST_BOARDS=$(cat $MODE_BOOT_DIR/board_data.json | grep "name" | tr -d [:blank:] | awk -F ":" '{print $2}' | sed -s 's/^"\(.*\)",$/\1/g')

# Who is using board
CURRENT_USER=$(whoami)
USER_USING_CONSOLE=($(ps axo pid,user:20,command | grep $SERIAL_PORT | grep "minicom\|miniterm" | grep -v grep | awk '{print $2}' || true))
USER_USING_SSH=($(ps axo pid,user:20,command | grep "ssh root@192.168.20.185" | grep -v grep | awk '{print $2}' | sort | uniq || true))

# Log directory
LOG_BOOT_BOARD=$WORK_DIR/logs/v4h/boot/$TIMELINE
LOG_BURN_BOARD=$WORK_DIR/logs/v4h/burn/$TIMELINE

if [[ ! -d $LOG_BOOT_BOARD ]]; then
    mkdir -p $LOG_BOOT_BOARD
fi

if [[ ! -d $LOG_BURN_BOARD ]]; then
    mkdir -p $LOG_BURN_BOARD
fi

usage() {
    cat << EOF
Usage:
    - Login to console terminal: ./board --login
    - Execute remote control for board: ./board -c [init|reset|off|burn]
E.g. 
    - Reset board and login to terminal: ./board -c reset --login

Options:
    --login (Required): Access to board's console terminal
    -b,--board (Optional): Define board name to access.
        Available boards can be checked at: /shsv/SS2/RSS1/qnx/remote-environment-rvc/source/01_Labpc/ModeSettingTool/board_data.json
    -s,--serial (Optional): Define serial port of the board. E.g. /dev/ttyUSB<x>
    -c,--command (Optional): Command to remotely control board.
        Args: 
            init: Initialize board after being OFF
            reset: Reset board while operating
            off: Turn OFF the board
            burn: Burn IPL for board

EOF
}

console() {
    options=$(getopt -o hc:b:s: -l help,login,command:,board:,serial: -- "$@")
    eval set -- $options
    while :; do
        case $1 in
            -h|--help)
                usage
                exit
                ;;
            -b|--board)
                BOARD_NAME=${2:-$BOARD_NAME}
                if [[ ! ${LIST_BOARDS[@]} =~ $BOARD_NAME ]]; then
                    echo>&2 "[ERROR] Unsupported board $BOARD_NAME!"; exit 1
                fi
                if [[ $BOARD_NAME =~ ^spider ]]; then
                    BAUDRATE=1843200
                elif [[ $BOARD_NAME =~ ^(whitehawk|grayhawk) ]]; then
                    BAUDRATE=921600
                else
                    BAUDRATE=115200
                fi
                shift 2
                ;;
            -s|--serial)
                SERIAL_PORT=${2:-$SERIAL_PORT}
                if [[ ! $SERIAL_PORT =~ \/dev\/ttyUSB[0-9]{1} ]]; then
                    echo>&2 -e "[ERROR] Wrong syntax for serial port\nPlease use this format: /dev/ttyUSBx"; exit 1
                fi
                shift 2
                ;;
            -c|--command)
                check_board_in_use
                if [[ $BOARD_NAME =~ ^(whitehawk|grayhawk) ]]; then
                    case $2 in
                        init)
                            python3 $MODE_BOOT_DIR/mode_setting.py -b $BOARD_NAME -m default
                            wait
                            python3 $MODE_BOOT_DIR/mode_setting.py -b $BOARD_NAME -m on
                            wait
                            python3 $MODE_BOOT_DIR/mode_setting.py -b $BOARD_NAME -m boot
                            wait
                            ;;
                        reset)
                            python3 $MODE_BOOT_DIR/mode_setting.py -b $BOARD_NAME -m reset
                            wait
                            ;;
                        off)
                            python3 $MODE_BOOT_DIR/mode_setting.py -b $BOARD_NAME -m off
                            exit
                            wait
                            ;;
                        burn)
                            if [[ -n $USER_USING_BOARD ]]; then
                                echo>&2 -e "[ERROR]: $USER_USING_BOARD is using board !\nPlease logout from console terminal before burning IPL"; exit 1
                            fi
                            python3 $MODE_BURN_DIR/flash_tool_cli.py flashwrite $IPL_DIR/Flash_V4H_White_Hawk.json $SERIAL_PORT --board $BOARD_NAME | tee $LOG_BURN_BOARD/burn.log
                            ;;
                        *)
                            echo>&2 "[ERROR] Unknown command $2"; exit 1
                            ;;
                    esac
                fi
                shift 2
                ;;
            --login)
                check_board_console
                if [[ $2 != "--" ]]; then
                    TOOL=$2
                else
                    TOOL=$LOGIN_TOOL
                fi
                case $TOOL in
                    miniterm)
                        python3 -m serial.tools.miniterm -f direct $SERIAL_PORT $BAUDRATE --eol LF --exit-char 31 | tee $LOG_BOOT_BOARD/boot.log
                        ;;
                    minicom)
                        minicom -b $BAUDRATE -D $SERIAL_PORT | tee $LOG_BOOT_BOARD/boot.log
                        ;;
                    *)
                        echo>&2 "[ERROR] Tool is unavailable on machine"; exit 1
                        ;;
                esac
                shift 2
                break
                ;;
            --)
                shift 1
                break
                ;;
        esac
    done
}

check_board_console() {
    if [[ -n $USER_USING_CONSOLE ]]; then
        for user in ${USER_USING_CONSOLE[@]}; do
            echo "[WARNING] $user is using board !"
        done
        exit 1
    fi
}

check_board_in_use() {
    if [[ -n $USER_USING_CONSOLE && -n $USER_USING_SSH ]]; then
        for user in ${USER_USING_CONSOLE[@]}; do
            echo "[WARNING] $user is using board !"
        done

        for user in ${USER_USING_SSH[@]}; do
            echo "[WARNING] $user is using board !"
        done

        read -p "Proceed ? [Y/n]: " input
        USR_INPUT=${input,,}
        if [[ ${USR_INPUT} == "n" ]]; then #Stop the execution if user don't want to reboot
            exit
        fi
    fi
}
# ---Main
if [[ $# -eq 0 ]]; then
    usage
    exit
fi
console $@
