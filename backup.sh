#!/bin/sh

# Check if db file is accessible and exit otherwise
if [ ! -e "$DB_FILE" ]
then 
  echo "Database $DB_FILE not found!\nPlease check if you mounted the bitwarden_rs volume with '--volumes-from=bitwarden'"!
  exit 1;
fi


# Check if ATTACHMENT_BACKUP_FILE exist. If it's true, attechment are backup. We define var with or without TIMESTAMP
# In anycase, we define var LOCALVAR_ATTACHMENT_BACKUP_FILE to limit the complexity of code (the number of if-else)
if [ ! -z $ATTACHMENT_BACKUP_FILE ]
then
  LOCALVAR_ATTACHMENT_BACKUP_FILE="$ATTACHMENT_BACKUP_FILE"
else
  LOCALVAR_ATTACHMENT_BACKUP_FILE=""
fi

# Check if SEND_BACKUP_FILE exist. If it's true, attechment are backup. We define var with or without TIMESTAMP
# In anycase, we define var LOCALVAR_SEND_BACKUP_FILE to limit the complexity of code (the number of if-else)
if [ ! -z $SEND_BACKUP_FILE ]
then
  LOCALVAR_SEND_BACKUP_FILE="$SEND_BACKUP_FILE"
else
  LOCALVAR_SEND_BACKUP_FILE=""
fi

if [ $TIMESTAMP = true ]
then
  FINAL_BACKUP_FILE="$(echo "$BACKUP_FILE")_$(date "+%F-%H%M%S")"
  FINAL_BACKUP_ATTACHMENT="$(echo "$LOCALVAR_ATTACHMENT_BACKUP_FILE")_$(date "+%F-%H%M%S")"
  FINAL_BACKUP_SEND="$(echo "$LOCALVAR_SEND_BACKUP_FILE")_$(date "+%F-%H%M%S")"
else
  FINAL_BACKUP_FILE=$BACKUP_FILE
  FINAL_BACKUP_ATTACHMENT=$LOCALVAR_ATTACHMENT_BACKUP_FILE
  FINAL_BACKUP_SEND=$LOCALVAR_SEND_BACKUP_FILE
fi


/usr/bin/sqlite3 $DB_FILE ".backup $FINAL_BACKUP_FILE"
if [ $? -eq 0 ]
then 
  echo "$(date "+%F %T") - Backup successfull to $FINAL_BACKUP_FILE"
else
  echo "$(date "+%F %T") - Backup unsuccessfull"
fi


if [ ! -z $ATTACHMENT_BACKUP_FILE ]
then
  echo "Create tar ${FINAL_BACKUP_ATTACHMENT}.tgz\n"
  /bin/tar -czf ${FINAL_BACKUP_ATTACHMENT}.tgz ${ATTACHMENT_DIR}
fi

if [ ! -z $SEND_BACKUP_FILE ]
then
  echo "Create tar ${FINAL_BACKUP_SEND}.tgz\n"
  /bin/tar -czf ${FINAL_BACKUP_SEND}.tgz ${SEND_DIR}
fi

if [ ! -z $DELETE_AFTER ] && [ $DELETE_AFTER -gt 0 ]
then
  find $(dirname "$BACKUP_FILE") -name "$(basename "$BACKUP_FILE")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;

  if [ ! -z $ATTACHMENT_BACKUP_FILE ]
  then
    find $(dirname "$FINAL_BACKUP_ATTACHMENT") -name "$(basename "$FINAL_BACKUP_ATTACHMENT")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
  fi

  if [ ! -z $SEND_BACKUP_FILE ]
  then
    find $(dirname "$FINAL_BACKUP_SEND") -name "$(basename "$FINAL_BACKUP_SEND")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
  fi
fi
