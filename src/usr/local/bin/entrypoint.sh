#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab
# shellcheck disable=SC3028

#set -x

# shellcheck source=/dev/null
. /opt/scripts/set-env.sh

# shellcheck source=/dev/null
. /opt/scripts/logging.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

# Allow start with custom commands
if [ "$#" -ne 0 ] && command -v "$@" > /dev/null 2>&1; then
  "$@"
  exit 0
fi

BACKUP_CMD="/sbin/su-exec ${UID}:${GID} /app/backup.sh"

debug "Running $(basename "$0") as $(id)"

# Warning for deprecated settings
if [ -n "$BACKUP_FILE" ]; then
  warn "\$BACKUP_FILE is deprecated and will be removed in future versions. Please use \$BACKUP_DIR instead to specify the folder of the backup."
  if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR=$(dirname "$BACKUP_FILE");
    warn "Since \$BACKUP_DIR is not set defaulting to BACKUP_DIR=$BACKUP_DIR"
  fi
fi

# Warning for deprecated settings
if [ -n "$BACKUP_FILE_PERMISSIONS" ]; then
  warn "\$BACKUP_FILE_PERMISSIONS is deprecated and will be removed in future versions. Please use \$BACKUP_DIR_PERMISSIONS instead to specify the permissions of the backup folder."
  if [ -z "$BACKUP_DIR_PERMISSIONS" ]; then
    BACKUP_DIR_PERMISSIONS="$BACKUP_FILE_PERMISSIONS";
    warn "Since \$BACKUP_DIR_PERMISSIONS is not set defaulting to BACKUP_DIR_PERMISSIONS=$BACKUP_FILE_PERMISSIONS"
  fi
fi

# Warning for deprecated settings
if [ -n "$DB_FILE" ]; then
  warn "\$DB_FILE is deprecated and will be removed in future versions. Please use \$VW_DATABASE_URL instead to specify the location of the source database file."
  if [ -z "$VW_DATABASE_URL" ]; then
    VW_DATABASE_URL="$DB_FILE";
    warn "Since \$VW_DATABASE_URL is not set defaulting to VW_DATABASE_URL=$DB_FILE"
  fi
fi

# Warning for deprecated settings
if [ -n "$ATTACHMENT_DIR" ]; then
  warn "\$ATTACHMENT_DIR is deprecated and will be removed in future versions. Please use \$VW_ATTACHMENTS_FOLDER instead to specify the location of the source attachments folder."
  if [ -z "$VW_ATTACHMENTS_FOLDER" ]; then
    VW_ATTACHMENTS_FOLDER="$ATTACHMENT_DIR";
    warn "Since \$VW_ATTACHMENTS_FOLDER is not set defaulting to VW_ATTACHMENTS_FOLDER=$ATTACHMENT_DIR"
  fi
fi

# Warning for deprecated settings
if [ -n "$ATTACHMENT_BACKUP_DIR" ]; then
  warn "\$ATTACHMENT_BACKUP_DIR is deprecated and will be removed in future versions. Attachment backups are stored in the \$BACKUP_DIR."
fi

# Warning for deprecated settings
if [ -n "$ATTACHMENT_BACKUP_FILE" ]; then
  warn "\$ATTACHMENT_BACKUP_FILE is deprecated and will be removed in future versions. Attachment backups are stored in the \$BACKUP_DIR."
fi

# Initialization
if [ ! -d "$BACKUP_DIR" ]
then
  info "Creating $BACKUP_DIR."
  install -o "$UID" -g "$GID" -m "$BACKUP_DIR_PERMISSIONS" -d "$BACKUP_DIR"
fi
info "Adjusting permissions for $BACKUP_DIR: Setting owner $UID:$GID and permissions $BACKUP_DIR_PERMISSIONS."
chown "$UID:$GID" "$BACKUP_DIR"
chmod -R "$BACKUP_DIR_PERMISSIONS" "$BACKUP_DIR"

# Just run the backup script
if [ "$1" = "manual" ]; then
  $BACKUP_CMD
  exit 0
fi

# Initialize cron
if [ "$(id -u)" -eq 0 ] && [ "$(grep -c "$BACKUP_CMD" "$CRONFILE")" -eq 0 ]; then
  info "Initalizing..."
  debug "Writing backup command \"$BACKUP_CMD\" to cron."
  echo "$CRON_TIME $BACKUP_CMD >> $LOGFILE 2>&1" | crontab -

fi

# Start crond if it's not running
if ! pgrep crond > /dev/null 2>&1; then
  /usr/sbin/crond -L /app/log/cron.log
fi

# Restart script as user "app:app"
if [ "$(id -u)" -eq 0 ]; then
  debug "Restarting $(basename "$0") as app:app"
  exec su-exec app:app "$0" "$@"
fi

info "Log level set to $LOG_LEVEL" > "$LOGFILE"
info "Container started" >> "$LOGFILE"
debug "Environment Variables:\n$(env)" >> "$LOGFILE"

# Include cron.log in debug mode
if [ "$LOG_LEVEL_NUMBER" -eq 7  ]; then
  tail -f -n +1 "$LOGFILE" /app/log/cron.log
fi

tail -f -n +1 "$LOGFILE"