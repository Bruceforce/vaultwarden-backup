#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab

#set -x

BACKUP_CMD="/sbin/su-exec ${UID}:${GID} /app/backup.sh"

# For compatibility reasons
if [ "$1" = "/backup.sh" ]; then
  >&2 echo "Using /backup.sh is deprecated and will be removed in future versions! Please use \`manual\` as arugment instead"
  $BACKUP_CMD
fi

# Just run the backup script
if [ "$1" = "manual" ]; then
  $BACKUP_CMD
fi

# Initialize cron
echo "Running as $(id)"
if [ "$(id -u)" -eq 0 ] && [ "$(grep -c "$BACKUP_CMD" "$CRONFILE")" -eq 0 ]; then
  echo "Initalizing..."
  echo "$CRON_TIME $BACKUP_CMD >> $LOGFILE 2>&1" | crontab -

fi

# Start crond if it's not running
pgrep crond > /dev/null 2>&1
if [ $? -ne 0 ]; then
  /usr/sbin/crond -L /app/log/cron.log
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
