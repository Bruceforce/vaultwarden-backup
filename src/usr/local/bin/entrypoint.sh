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

# Permissions
adjust_permissions() {
  if [ "$APP_DIR_PERMISSIONS" -ne -1 ]; then
    debug "Adjusting permissions for $APP_DIR: Setting owner $UID:$GID and permissions $APP_DIR_PERMISSIONS."
    chown -R "$UID:$GID" "$APP_DIR"
    chmod -R "$APP_DIR_PERMISSIONS" "$APP_DIR"
  else
    info "\$APP_DIR_PERMISSIONS set to -1. Skipping adjustment of permissions."
  fi

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

  if [ "$HEALTHCHECK_FILE_PERMISSIONS" -ne -1 ]; then
    debug "Adjusting permissions for $HEALTHCHECK_FILE: Setting owner $UID:$GID and permissions $HEALTHCHECK_FILE_PERMISSIONS."
    touch "$HEALTHCHECK_FILE"
    chown -R "$UID:$GID" "$HEALTHCHECK_FILE"
    chmod -R "$HEALTHCHECK_FILE_PERMISSIONS" "$HEALTHCHECK_FILE"
  else
    info "\$HEALTHCHECK_FILE_PERMISSIONS set to -1. Skipping adjustment of permissions."
  fi
}

# Initialization
init_folders() {
  if [ ! -d "$BACKUP_DIR" ]; then
    info "Creating $BACKUP_DIR."
    install -o "$UID" -g "$GID" -m "$BACKUP_DIR_PERMISSIONS" -d "$BACKUP_DIR"
  fi

  if [ ! -f "$APP_DIR" ]; then
    info "Creating $APP_DIR."
    install -o "$UID" -g "$GID" -m "$APP_DIR_PERMISSIONS" -d "$APP_DIR"
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