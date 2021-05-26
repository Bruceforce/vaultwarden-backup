#!/bin/sh

# Create variable for new backup zip.
BACKUP_ZIP=/backups/$(date "+%F_%H.%M.%S").zip

# Create variables for the files and directories to be zipped.
BACKUP_DB=db.sqlite3 # file
BACKUP_RSA=rsa_key* # files
BACKUP_CONFIG=config.json # file
BACKUP_ATTACHMENTS=attachments # directory
BACKUP_SENDS=sends # directory

# Create a zip of the files and directories.
cd /data && zip -r $BACKUP_ZIP $BACKUP_DB $BACKUP_RSA $BACKUP_CONFIG $BACKUP_ATTACHMENTS $BACKUP_SENDS && cd ..
