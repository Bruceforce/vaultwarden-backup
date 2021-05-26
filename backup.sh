#!/bin/sh

# Create variable for new backup zip.
BACKUP_ZIP=/backups/$(date "+%F_%H.%M.%S").zip

# Create variables for the files and directories to be zipped.
BACKUP_DB=/data/db.sqlite3
BACKUP_RSA=/data/rsa_key*
BACKUP_CONFIG=/data/config.json
BACKUP_ATTACHMENTS=/data/attachments
BACKUP_SENDS=/data/sends

# Create a zip of the files and directories.
#zip -r $BACKUP_ZIP $BACKUP_DB $BACKUP_RSA $BACKUP_CONFIG $BACKUP_ATTACHMENTS $BACKUP_SENDS
cd /data && zip -r $BACKUP_ZIP $BACKUP_DB $BACKUP_RSA $BACKUP_CONFIG $BACKUP_ATTACHMENTS $BACKUP_SENDS && cd ..

# Copy files and directories (db, rsa_key, config, attachments and sends).
#cp /data/db.sqlite3 $BACKUP_DIRECTORY
#cp /data/rsa_key* $BACKUP_DIRECTORY
#cp /data/config.json $BACKUP_DIRECTORY 2>/dev/null || :
#cp -R /data/attachments $BACKUP_DIRECTORY 2>/dev/null || :
#cp -R /data/sends $BACKUP_DIRECTORY 2>/dev/null || :

#if [ ! -z $DELETE_AFTER ] && [ $DELETE_AFTER -gt 0 ]
#then
#  find $(dirname "$BACKUP_FILE") -name "$(basename "$BACKUP_FILE")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
#fi
