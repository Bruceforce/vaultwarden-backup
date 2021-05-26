#!/bin/sh

BACKUP_CMD="/sbin/su-exec ${UID}:${GID} /app/backup.sh"

echo "Running $(basename "$0") as $(id)"

# Run backup script once ($1 = First argument passed).
if [ "$1" = "manual" ]; then
  $BACKUP_CMD
  exit 0
fi

# Initialize cron
if [ "$(id -u)" -eq 0 ] && [ "$(grep -c "$BACKUP_CMD" "$CRONFILE")" -eq 0 ]; then
  echo "Initalizing..."
  echo "Writing backup command \"$BACKUP_CMD\" to cron."
  echo "$CRON_TIME $BACKUP_CMD >> $LOGFILE 2>&1" | crontab -
fi

# Start crond if it's not running
pgrep crond > /dev/null 2>&1
if [ $? -ne 0 ]; then
  /usr/sbin/crond -L /app/log/cron.log
fi

# Restart script as user "app:app"
if [ "$(id -u)" -eq 0 ]; then
  echo "Restarting $(basename "$0") as app:app"
  exec su-exec app:app "$0" "$@"
fi

echo "$(date "+%F %T") - Container started" > "$LOGFILE"
tail -F "$LOGFILE" /app/log/cron.log
