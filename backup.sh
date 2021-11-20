#!/bin/bash

# Check if db file is accessible and exit otherwise
if [ ! -e "$DB_FILE" ]; then 
  printf "Database %s not found!\nPlease check if you mounted the bitwarden_rs volume with '--volumes-from=bitwarden'!\n" "$DB_FILE"
  exit 1;
fi

# Check if ATTACHMENT_BACKUP_FILE exist. If it's true, attechment are backup. We define var with or without TIMESTAMP
# In anycase, we define var LOCALVAR_ATTACHMENT_BACKUP_FILE to limit the complexity of code (the number of if-else)
if [ -n "$ATTACHMENT_BACKUP_FILE" ]; then
  LOCALVAR_ATTACHMENT_BACKUP_FILE="$ATTACHMENT_BACKUP_FILE"
else
  LOCALVAR_ATTACHMENT_BACKUP_FILE=""
fi

# Attach timestamps to filenames if variable is set to true
if [ "$TIMESTAMP" = true ]; then
  FINAL_BACKUP_FILE="${BACKUP_FILE}_$(date "+%F-%H%M%S")"
  FINAL_BACKUP_ATTACHMENT="${LOCALVAR_ATTACHMENT_BACKUP_FILE}_$(date "+%F-%H%M%S")"
else
  FINAL_BACKUP_FILE=$BACKUP_FILE
  FINAL_BACKUP_ATTACHMENT=$LOCALVAR_ATTACHMENT_BACKUP_FILE
fi

# Run the backup command for the database file
if /usr/bin/sqlite3 "$DB_FILE" ".backup $FINAL_BACKUP_FILE"; then 
  echo "$(date "+%F %T") - Database backup successfull to $FINAL_BACKUP_FILE"
else
  echo "$(date "+%F %T") - Database backup unsuccessfull"
fi

# Run the backup command for the attachments folder
if [ -n "$ATTACHMENT_BACKUP_FILE" ] && /bin/tar -czf "${FINAL_BACKUP_ATTACHMENT}.tgz" "${ATTACHMENT_DIR}"; then
  echo "$(date "+%F %T") - Attachment backup successfull to $FINAL_BACKUP_ATTACHMENT.tgz"
else
  echo "$(date "+%F %T") - Attachment backup unsuccessfull"
fi

# Delete backup files after $DELETE_AFTER days.
if [ -n "$DELETE_AFTER" ] && [ "$DELETE_AFTER" -gt 0 ]; then
  find "$(dirname "$BACKUP_FILE")" -name "$(basename "$BACKUP_FILE")*" -type f -mtime +"$DELETE_AFTER" -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;

  if [ -n "$ATTACHMENT_BACKUP_FILE" ]; then
    find "$(dirname "$ATTACHMENT_BACKUP_FILE")" -name "$(basename "$ATTACHMENT_BACKUP_FILE")*" -type f -mtime +"$DELETE_AFTER" -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
  fi
fi
