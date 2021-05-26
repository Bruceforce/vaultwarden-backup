#!/bin/sh

# Create variable for new backup zip.
BACKUP_ZIP=/backups/$(date "+%F_%H.%M.%S").zip

# Go inside data folder.
cd /data

# Create variables for the files and folders to be zipped.
BACKUP_DB=db.sqlite3
BACKUP_RSA=rsa_key*
BACKUP_CONFIG=config.json
BACKUP_ATTACHMENTS=/attachments
BACKUP_SENDS=/sends

# Create a zip of the files and folders.
zip -r ../$BACKUP_ZIP $BACKUP_DB $BACKUP_RSA $BACKUP_CONFIG $BACKUP_ATTACHMENTS $BACKUP_SENDS

# Leave data folder.
cd ..

# Copy files and folders (db, rsa_key, config, attachments and sends).
#cp /data/db.sqlite3 $BACKUP_FOLDER
#cp /data/rsa_key* $BACKUP_FOLDER
#cp /data/config.json $BACKUP_FOLDER 2>/dev/null || :
#cp -R /data/attachments $BACKUP_FOLDER 2>/dev/null || :
#cp -R /data/sends $BACKUP_FOLDER 2>/dev/null || :

#if [ ! -z $DELETE_AFTER ] && [ $DELETE_AFTER -gt 0 ]
#then
#  find $(dirname "$BACKUP_FILE") -name "$(basename "$BACKUP_FILE")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
#fi
