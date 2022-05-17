#!/bin/sh

# shellcheck disable=SC1091

. /opt/scripts/logging.sh
. /opt/scripts/set-env.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

### Functions ###

# Initialize variables
init() {
  if [ "$TIMESTAMP" = true ]; then
    TIMESTAMP_PREFIX="$(date "+%F-%H%M%S")_"
  fi

  BACKUP_FILE_DB=$BACKUP_DIR/${TIMESTAMP_PREFIX}db.sqlite3
  BACKUP_FILE_DATA=$BACKUP_DIR/${TIMESTAMP_PREFIX}data.tar.gz

  # Check if db file is accessible and exit otherwise
  if [ ! -e "$VW_DATABASE_URL" ]; then 
    critical "Database $VW_DATABASE_URL not found! Please check if you mounted the bitwarden_rs volume with '--volumes-from=vaultwarden'!" >> "$LOGFILE_APP"
  fi
}

# Backup the database
backup_database() {
  if /usr/bin/sqlite3 "$VW_DATABASE_URL" ".backup '$BACKUP_FILE_DB'"; then 
    info "Backup of the database to $BACKUP_FILE_DB was successfull" >> "$LOGFILE_APP"
  else
    error "Backup of the database failed" >> "$LOGFILE_APP"
  fi
}

# Backup additional data like attachments, sends, etc.
backup_additional_data() {
  if [ "$BACKUP_ADD_ATTACHMENTS" = true ] && [ -e "$VW_ATTACHMENTS_FOLDER" ]; then set -- "$VW_ATTACHMENTS_FOLDER"; fi
  if [ "$BACKUP_ADD_ICON_CACHE" = true ] && [ -e "$VW_ICON_CACHE_FOLDER" ]; then set -- "$@" "$VW_ICON_CACHE_FOLDER"; fi
  if [ "$BACKUP_ADD_SENDS" = true ] && [ -e "$VW_DATA_FOLDER/sends" ]; then set -- "$@" "$VW_DATA_FOLDER/sends"; fi
  if [ "$BACKUP_ADD_CONFIG_JSON" = true ] && [ -e "$VW_DATA_FOLDER/config.json" ]; then set -- "$@" "$VW_DATA_FOLDER/config.json"; fi
  if [ "$BACKUP_ADD_RSA_KEY" = true ]; then
    rsa_keys="$(find "$VW_DATA_FOLDER" -iname 'rsa_key*')"
    debug "found RSA keys $rsa_keys" >> "$LOGFILE_APP"
    for rsa_key in $rsa_keys; do
      set -- "$@" "$rsa_key"
    done
  fi

  debug "\$@ is: $*" >> "$LOGFILE_APP"
  loop_ctr=0
  for i in "$@"; do
    if [ "$loop_ctr" -eq 0 ]; then debug "Clear \$@ on first loop" >> "$LOGFILE_APP"; set --; fi

    # Prevent the "leading slash" warning from tar command
    if [ "$(dirname "$i")" = "$VW_DATA_FOLDER" ]; then
      debug "dirname of $i matches $VW_DATA_FOLDER. This means we can scrap it." >> "$LOGFILE_APP"
      set -- "$@" "$(basename "$i")"
    fi

    loop_ctr=$((loop_ctr+1))
  done

  debug "Backing up: $*" >> "$LOGFILE_APP"

  # Run the backup command for additional data folders
  # We need to use the "cd" here instead of "tar -C ..." because of the wildcard for RSA keys.
  #"$(cd "$VW_DATA_FOLDER" && bin/tar -czf "$BACKUP_FILE_DATA" "$@")"
  if /bin/tar -czf "$BACKUP_FILE_DATA" -C "$VW_DATA_FOLDER" "$@"; then
    info "Backup of additional data folders to $BACKUP_FILE_DATA was successfull" >> "$LOGFILE_APP"
  else
    error "Backup of additional data folders failed" >> "$LOGFILE_APP"
  fi
}

# Performs a healthcheck
perform_healthcheck() {
  debug "\$error_counter=$error_counter" >> "$LOGFILE_APP"
  if [ "$error_counter" -ne 0 ]; then
    warn "There were $error_counter errors during backup. Skipping health check." >> "$LOGFILE_APP"
    return 1
  fi
  debug "Evaluating \$HEALTHCHECK_URL" >> "$LOGFILE_APP"
  if [ -z "$HEALTHCHECK_URL" ]; then
    debug "Variable \$HEALTHCHECK_URL not set. Skipping health check." >> "$LOGFILE_APP"
    return 0
  fi
  info "Running health check ping" >> "$LOGFILE_APP"
  wget "$HEALTHCHECK_URL" -T 10 -t 5 -q -O /dev/null
}

cleanup() {
  if [ -n "$DELETE_AFTER" ] && [ "$DELETE_AFTER" -gt 0 ]; then
    if [ "$TIMESTAMP" != true ]; then warn "DELETE_AFTER will most likely have no effect because TIMESTAMP is not set to true." >> "$LOGFILE_APP"; fi
    find "$BACKUP_DIR" -type f -mtime +"$DELETE_AFTER" -exec sh -c '. /opt/scripts/logging.sh; file="$1"; rm -f "$file"; info "Deleted backup "$file" after $DELETE_AFTER days"' shell {} \;  >> "$LOGFILE_APP"
  fi
}

### Main ###

# Run init
init

# Dunp env if INFO or DEBUG
[ "$LOG_LEVEL_NUMBER" -ge 6 ] && (set > "${LOG_DIR}/env.txt")

# Run the backup command for the database file
if [ "$BACKUP_ADD_DATABASE" = true ]; then
  backup_database
fi

# Run the backup command for additional data folders
if [ "$BACKUP_ADD_ATTACHMENTS" = true ] \
    || [ "$BACKUP_ADD_CONFIG_JSON" = true ] \
    || [ "$BACKUP_ADD_ICON_CACHE" = true ] \
    || [ "$BACKUP_ADD_RSA_KEY" = true ] \
    || [ "$BACKUP_ADD_SENDS" = true ]; then
  backup_additional_data
fi

# Perform healthcheck
perform_healthcheck

# Delete backup files after $DELETE_AFTER days.
cleanup
