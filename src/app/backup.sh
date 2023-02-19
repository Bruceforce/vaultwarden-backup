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

  BACKUP_FILE_DB=/tmp/db.sqlite3
  BACKUP_FILE_ARCHIVE="$BACKUP_DIR/${TIMESTAMP_PREFIX}backup.tar.xz"

    if [ ! -f "$VW_DATABASE_URL" ]; then
      printf 1 > "$HEALTHCHECK_FILE"
      critical "Database $VW_DATABASE_URL not found! Please check if you mounted the vaultwarden volume (in docker-compose or with '--volumes-from=vaultwarden'!)"
  fi
}

# Backup database and additional data like attachments, sends, etc.
backup() {
  # First we backup the database to a temporary file (this will later be added to a tar archive)
  if [ "$BACKUP_ADD_DATABASE" = true ] && /usr/bin/sqlite3 "$VW_DATABASE_URL" ".backup '$BACKUP_FILE_DB'"; then
    set -- "$BACKUP_FILE_DB"
    debug "Written temporary backup file to $BACKUP_FILE_DB"
  else
    error "Backup of the database failed"
  fi

  # We use this technique to simulate an array in a POSIX compliant way
  if [ "$BACKUP_ADD_ATTACHMENTS" = true ] && [ -e "$VW_ATTACHMENTS_FOLDER" ]; then set -- "$@" "$VW_ATTACHMENTS_FOLDER"; fi
  if [ "$BACKUP_ADD_ICON_CACHE" = true ] && [ -e "$VW_ICON_CACHE_FOLDER" ]; then set -- "$@" "$VW_ICON_CACHE_FOLDER"; fi
  if [ "$BACKUP_ADD_SENDS" = true ] && [ -e "$VW_DATA_FOLDER/sends" ]; then set -- "$@" "$VW_DATA_FOLDER/sends"; fi
  if [ "$BACKUP_ADD_CONFIG_JSON" = true ] && [ -e "$VW_DATA_FOLDER/config.json" ]; then set -- "$@" "$VW_DATA_FOLDER/config.json"; fi
  if [ "$BACKUP_ADD_RSA_KEY" = true ]; then
    rsa_keys="$(find "$VW_DATA_FOLDER" -iname 'rsa_key*')"
    debug "found RSA keys: $rsa_keys"
    for rsa_key in $rsa_keys; do
      set -- "$@" "$rsa_key"
    done
  fi

  # Here we assemble the array and strip off the root paths (e.g. /backup)
  debug "\$@ is: $*"
  loop_ctr=0
  for i in "$@"; do
    if [ "$loop_ctr" -eq 0 ]; then debug "Clear \$@ on first loop"; set --; fi

    # Ensure that database will be put into the root folder of the backup archive
    if [ "$i" = "$BACKUP_FILE_DB" ]; then
      debug "filepath of $i matches $BACKUP_FILE_DB. This means we can put this into the root folder of the backup archive."
      set -- "$@" "$(basename "$i")"
    fi

    # Prevent the "leading slash" warning from tar command
    if [ "$(dirname "$i")" = "$VW_DATA_FOLDER" ]; then
      debug "dirname of $i matches $VW_DATA_FOLDER. This means we can scrap it."
      set -- "$@" "$(basename "$i")"
    fi

    loop_ctr=$((loop_ctr+1))
  done

  debug "Backing up: $*"

  # Here we create the backup tar archive with optional encryption
  if [ "$ENCRYPTION_BASE64_GPG_KEY" != false ] && [ "$ENCRYPTION_PASSWORD" != false ]; then
    warn "Ignoring ENCRYPTION_PASSWORD since you set both ENCRYPTION_BASE64_GPG_KEY and ENCRYPTION_PASSWORD."
  fi

  if [ -f "$ENCRYPTION_GPG_KEYFILE_LOCATION" ]; then
    # Create a backup with public key encryption
    if /bin/tar -cJ -C "$VW_DATA_FOLDER" "$@" | gpg --batch --no-options --no-tty --yes --encrypt \
        --recipient-file "$ENCRYPTION_GPG_KEYFILE_LOCATION" -o "$BACKUP_FILE_ARCHIVE.gpg"; then
      info "Successfully created gpg (public key) encrypted backup $BACKUP_FILE_ARCHIVE.gpg"
    else
      error "Encrypted backup failed!"
    fi
  elif [ ! "$ENCRYPTION_PASSWORD" = false ]; then
    # Create a backup with symmetric encryption
    if /bin/tar -cJ -C "$VW_DATA_FOLDER" "$@" | gpg --batch --no-options --no-tty --yes --symmetric \
        --passphrase "$ENCRYPTION_PASSWORD" --cipher-algo "$ENCRYPTION_ALGORITHM" -o "$BACKUP_FILE_ARCHIVE.gpg"; then
      info " Successfully created gpg (password) encrypted backup $BACKUP_FILE_ARCHIVE.gpg"
    else
      error "Encrypted backup failed!"
    fi
  else
    # Create a backup without encryption
    if /bin/tar -cJf "$BACKUP_FILE_ARCHIVE" -C "$VW_DATA_FOLDER" "$@"; then
      info "Successfully created backup $BACKUP_FILE_ARCHIVE"
    else
      error "Backup failed"
    fi
  fi
  rm "$BACKUP_FILE_DB"
}

# Performs a healthcheck
perform_healthcheck() {
  debug "\$error_counter=$error_counter"

  if [ "$error_counter" -ne 0 ]; then
    warn "There were $error_counter errors during backup. Not sending health check ping."
    printf 1 > "$HEALTHCHECK_FILE"
    return 1
  fi

  # At this point the container is healthy. So we create a health-check file used to determine container health
  # and send a health check ping if the HEALTHCHECK_URL is set.
  printf 0 > "$HEALTHCHECK_FILE"
  debug "Evaluating \$HEALTHCHECK_URL"
  if [ -z "$HEALTHCHECK_URL" ]; then
    debug "Variable \$HEALTHCHECK_URL not set. Skipping health check."
    return 0
  fi
  
  info "Sending health check ping."
  wget "$HEALTHCHECK_URL" -T 10 -t 5 -q -O /dev/null
}

cleanup() {
  if [ -n "$DELETE_AFTER" ] && [ "$DELETE_AFTER" -gt 0 ]; then
    if [ "$TIMESTAMP" != true ]; then warn "DELETE_AFTER will most likely have no effect because TIMESTAMP is not set to true."; fi
    find "$BACKUP_DIR" -type f -mtime +"$DELETE_AFTER" -exec sh -c '. /opt/scripts/logging.sh; file="$1"; rm -f "$file"; info "Deleted backup "$file" after $DELETE_AFTER days"' shell {} \; 
  fi
}

### Main ###

# Run init
init

# Run the backup command
backup

# Perform healthcheck
perform_healthcheck

# Delete backup files after $DELETE_AFTER days.
cleanup
