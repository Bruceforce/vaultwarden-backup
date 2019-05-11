#!/bin/sh

#set -ux

BACKUP_CMD="/sbin/su-exec ${UID}:${GID} /app/backup.sh"

echo "Running as $(id)"
if [ "$(id -u)" -eq 0 ] && [ "$(grep -c "$BACKUP_CMD" "$CRONFILE")" -eq 0 ]; then
  echo "Initalizing..."
  echo "$CRON_TIME $BACKUP_CMD >> $LOGFILE 2>&1" | crontab -

  # Start crond if it's not running
  pgrep crond > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    /usr/sbin/crond -L /app/log/cron.log
  fi
fi

# Restart script as user "app:app"
if [ "$(id -u)" -eq 0 ]; then
  exec su-exec app:app "$0" "$@"
fi

if [ ! -e "$DB_FILE" ]
then 
  echo "Database $DB_FILE not found!\nPlease check if you mounted the bitwarden_rs volume with '--volumes-from=bitwarden'"!
  exit 1;
fi

echo "$(date "+%F %T") - Container started" > "$LOGFILE"
tail -F "$LOGFILE" /app/log/cron.log
