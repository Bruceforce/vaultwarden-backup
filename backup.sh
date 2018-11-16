#!/bin/sh

/usr/bin/sqlite3 $DB_FILE ".backup $BACKUP_FILE"
if [ $? -eq 0 ] 
then 
  echo "$(date) - Backup successfull"
else
  echo "$(date) - Backup unsuccessfull"
fi
