#!/bin/bash

# load variables
. /opt/backup/config.sh

PWD=$(pwd)

cd / &&
tar -czvf "$BACKUP" $BACKUP_FILES
cd "$PWD"
