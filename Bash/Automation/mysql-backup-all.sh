#!/bin/bash
set -eou pipefail

SRC_USR="<username>"
SRC_PSW="<password>"
BACKUP_DIR="/path/to/backup/directory"
BACKUP_FILE="mysql_bk_$(date +%Y%m%d).sql"
MAX_BK=5

mysqldump -u $SRC_USR -p $SRC_PSW --single-transaction --all-databases > $BACKUP_DIR/$BACKUP_FILE

BACKUPS=($BACKUP_DIR/mysql_bk_*.sql)
NUM_BACKUPS=${#BACKUPS[@]}
if [[ $NUM_BACKUPS -gt $MAX_BK ]]; then
    NUM_TO_DELETE=$(($NUM_BACKUPS - $MAX_BK))
    BACKUP_TO_DELETES=(${BACKUPS[@]:0:$NUM_TO_DELETE})
    rm ${BACKUP_TO_DELETES[@]}
fi