#!/bin/sh
# vim: tabstop=2 shiftwidth=2 expandtab
# shellcheck disable=SC3028
# shellcheck disable=SC1091

#set -x

. /opt/scripts/set-env.sh

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

### Functions ###

check_deprecations() {
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
  if [ -n "$LOGFILE" ]; then
    warn "\$LOGFILE is deprecated and will be removed in future versions. Please use \$LOG_DIR instead to specify the location of the logfile folder."
    if [ -z "$LOG_DIR" ]; then
      LOG_DIR="$(dirname "$(realpath "$LOGFILE")")";
      warn "Since \$LOG_DIR is not set defaulting to LOG_DIR=$LOG_DIR"
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
}

# Permissions
adjust_permissions() {
  if [ "$BACKUP_DIR_PERMISSIONS" -ne -1 ]; then
    debug "Adjusting permissions for $BACKUP_DIR: Setting owner $UID:$GID and permissions $BACKUP_DIR_PERMISSIONS."
    chown -R "$UID:$GID" "$BACKUP_DIR"
    chmod -R "$BACKUP_DIR_PERMISSIONS" "$BACKUP_DIR"
  else
    info "\$BACKUP_DIR_PERMISSIONS set to -1. Skipping adjustment of permissions."
  fi

  if [ "$LOG_DIR_PERMISSIONS" -ne -1 ]; then
    debug "Adjusting permissions for $LOG_DIR: Setting owner $UID:$GID and permissions $LOG_DIR_PERMISSIONS."
    chown -R "$UID:$GID" "$LOG_DIR"
    chmod -R "$LOG_DIR_PERMISSIONS" "$LOG_DIR"
  else
    info "\$LOG_DIR_PERMISSIONS set to -1. Skipping adjustment of permissions."
  fi
}

# Initialization
init_folders() {
  if [ ! -d "$BACKUP_DIR" ]; then
    info "Creating $BACKUP_DIR."
    install -o "$UID" -g "$GID" -m "$BACKUP_DIR_PERMISSIONS" -d "$BACKUP_DIR"
  fi

  if [ ! -d "$LOG_DIR" ]; then
    info "Creating $LOG_DIR."
    install -o "$UID" -g "$GID" -m "$LOG_DIR_PERMISSIONS" -d "$LOG_DIR"
  fi
}

# Initialize cron
init_cron() {
  if [ "$(grep -c "$BACKUP_CMD" "$CRONFILE")" -eq 0 ]; then
    info "Initalizing $CRONFILE"
    debug "Writing backup command \"$BACKUP_CMD\" to $CRONFILE."
    echo "$CRON_TIME $BACKUP_CMD >> $LOGFILE_APP 2>&1" | crontab -
  fi

  # Start crond if it's not running
  if ! pgrep crond > /dev/null 2>&1; then
    /usr/sbin/crond -L "$LOGFILE_CRON"
  fi
}

# Initialize logfiles
init_log() {
  su-exec "$UID:$GID" touch "$LOGFILE_CRON"
  su-exec "$UID:$GID" touch "$LOGFILE_APP"
  info "Running vaultwarden-backup version $VW_BACKUP_VERSION"
  info "Log level set to $LOG_LEVEL" > "$LOGFILE_APP"
  info "Container started" >> "$LOGFILE_APP"
  debug "Environment Variables:\n$(env | sort)" >> "$LOGFILE_APP"
}

# Run backup in manual mode and exit
manual_mode() {
  info "Running in manual mode." >> "$LOGFILE_APP"
  $BACKUP_CMD
  cat "$LOGFILE_APP"
  exit 0
}

### Main ###

# Init only when run as root because of permissions
if [ "$(id -u)" -eq 0 ]; then
  check_deprecations
  init_folders
  init_log
  adjust_permissions
  if [ "$1" = "manual" ]; then manual_mode; fi
  init_cron
fi

# Restart script as desired user
if [ "$(id -u)" -ne "$UID" ]; then
  debug "Restarting $(basename "$0") as $UID:$GID"
  exec su-exec "$UID:$GID" "$0" "$@"
fi

# Include cron.log in debug mode
if [ "$LOG_LEVEL_NUMBER" -eq 7  ]; then
  tail -f -n +1 "$LOGFILE_APP" "$LOGFILE_CRON"
fi

tail -f -n +1 "$LOGFILE_APP"