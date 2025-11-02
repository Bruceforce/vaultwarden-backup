#!/bin/sh

# shellcheck disable=SC1091

. /opt/scripts/logging.sh
. /opt/scripts/set-env.sh
. /opt/scripts/helper.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

### Functions ###
#######################################
# Initializes variables
# Arguments:
#   None
# Returns:
#   None
#######################################
init() {
  if [ "$TIMESTAMP" = true ]; then
    TIMESTAMP_PREFIX="$(date "+%F-%H%M%S")_"
  fi

  if [ "$BACKUP_USE_DEDUPE" = true ]; then source_config; fi

  TEMP_BACKUP_DIR=/tmp/backupfiles
  TEMP_BACKUP_ARCHIVE="/tmp/temp-backup.tar.xz"
  BACKUP_FILE_DB="$TEMP_BACKUP_DIR/db.sqlite3"
  BACKUP_FILE_ARCHIVE="$BACKUP_DIR/${TIMESTAMP_PREFIX}backup.tar.xz"
  BACKUP_FILE_REGEX=".*backup\.tar\.xz\(\.gpg\)\?" # search for previous backup files matching these patterns
  ENCRYPTION_MODE="none"
  mkdir "$TEMP_BACKUP_DIR"

  # Add ".gpg" extension if encryption is used
  if [ "$ENCRYPTION_BASE64_GPG_KEY" != false ] || [ "$ENCRYPTION_PASSWORD" != false ]; then
    BACKUP_FILE_ARCHIVE="$BACKUP_DIR/${TIMESTAMP_PREFIX}backup.tar.xz.gpg"
  fi

  # Determine encryption mode
  if [ "$ENCRYPTION_BASE64_GPG_KEY" != false ] && [ "$ENCRYPTION_PASSWORD" != false ]; then
    warn "Ignoring ENCRYPTION_PASSWORD since you set both ENCRYPTION_BASE64_GPG_KEY and ENCRYPTION_PASSWORD."
    ENCRYPTION_MODE="asymmetric"
  elif [ -f "$ENCRYPTION_GPG_KEYFILE_LOCATION" ]; then
    ENCRYPTION_MODE="asymmetric"
  elif [ ! "$ENCRYPTION_PASSWORD" = false ]; then
    ENCRYPTION_MODE="symmetric"
  fi

  if [ ! -f "$VW_DATABASE_URL" ]; then
    printf 1 > "$HEALTHCHECK_FILE"
    critical "Database $VW_DATABASE_URL not found! Please check if you mounted the vaultwarden volume (in docker-compose or with '--volumes-from=vaultwarden'!)"
  fi
}

#######################################
# Creates a temporary archive.
# This archive is used afterwards depending on the backup mode
# (simple, symmetric encrypted, asymmetric encrypted).
# Arguments:
#   None
# Returns:
#   None
#######################################
create_temporary_archive() {
  # First we backup the database to a temporary file (this will later be added to a tar archive)
  if [ "$BACKUP_ADD_DATABASE" = true ] && /usr/bin/sqlite3 "$VW_DATABASE_URL" ".backup '$BACKUP_FILE_DB'"; then
    debug "Written temporary database backup file to $BACKUP_FILE_DB"
  else
    error "Backup of the database failed"
  fi

  # Copy all files to a temporary location. This makes calculating hashsums and building the tar archive easier.
  if [ "$BACKUP_ADD_ATTACHMENTS" = true ] && [ -e "$VW_ATTACHMENTS_FOLDER" ]; then cp -a "$VW_ATTACHMENTS_FOLDER" "$TEMP_BACKUP_DIR"; fi
  if [ "$BACKUP_ADD_ICON_CACHE" = true ] && [ -e "$VW_ICON_CACHE_FOLDER" ]; then cp -a "$VW_ICON_CACHE_FOLDER" "$TEMP_BACKUP_DIR"; fi
  if [ "$BACKUP_ADD_SENDS" = true ] && [ -e "$VW_DATA_FOLDER/sends" ]; then cp -a "$VW_DATA_FOLDER/sends" "$TEMP_BACKUP_DIR/sends"; fi
  if [ "$BACKUP_ADD_CONFIG_JSON" = true ] && [ -e "$VW_DATA_FOLDER/config.json" ]; then cp -a "$VW_DATA_FOLDER/config.json" "$TEMP_BACKUP_DIR/config.json"; fi
  if [ "$BACKUP_ADD_RSA_KEY" = true ]; then find "$VW_DATA_FOLDER" -iname 'rsa_key*' -exec cp -a {} "$TEMP_BACKUP_DIR" \;; fi

  # Create a temporary unencrypted backup archive
  debug "Current tar command: /bin/tar -cJf $TEMP_BACKUP_ARCHIVE -C $TEMP_BACKUP_DIR" .
  if eval /bin/tar -cJf "$TEMP_BACKUP_ARCHIVE" -C "$TEMP_BACKUP_DIR" .; then
    debug "Written temporary  tar archive to $TEMP_BACKUP_ARCHIVE"
  else
    error "Database backup failed"
  fi

  if [ "$BACKUP_USE_DEDUPE" = true ]; then
    # Generate hash of the files and store it in configuration file
    latest_backup_contenthash=$(find "$TEMP_BACKUP_DIR" -type f -exec "$BACKUP_HASHING_EXEC" {} \; | LC_ALL=C sort | sha256sum | awk '{print $1}')
    update_config "contenthash" "$latest_backup_contenthash"
  fi
}


#######################################
# Function to create a simple backup without encryption
# Arguments:
#   None
# Returns:
#   0 if the backup was successful
#######################################
create_simple_backup() {
  create_temporary_archive
  debug "Creating backup without encryption"
  create_new_backup=true

  # If DEDUPE is enabled, a previous backup exists, and the contents have NOT changed, then copy the previous backup
  if [ "$BACKUP_USE_DEDUPE" = true ]; then
    if is_enc_mode_changed || is_backup_content_changed; then
      info "Changes detected since last backup. Creating new backup file."
    else
      info "No changes detected since last backup. Dedupe enabled. No new backup file was created."
      create_new_backup=false
    fi
  fi

  if [ "$create_new_backup" = true ]; then
    if eval cp -a "$TEMP_BACKUP_ARCHIVE" "$BACKUP_FILE_ARCHIVE"; then
      info "Successfully created backup"
      return 0
    else
      error "Failed to create backup!"
      return 1
    fi
  fi

  return 2
}

#######################################
# Function to create a backup with asymmetric encryption
# Arguments:
#   None
# Returns:
#   0 if the backup was successful
#######################################
create_asym_encrypted_backup() {
  create_temporary_archive
  debug "Encrypting using GPG Keyfile"
  create_new_backup=true

  if [ "$BACKUP_USE_DEDUPE" = true ]; then
    if is_asym_key_changed || is_enc_mode_changed || is_backup_content_changed; then
      info "Changes detected since last backup (either key or backup content changed). Creating new backup file."
    else
      info "No changes detected since last backup. Dedupe enabled. No new backup file was created."
      create_new_backup=false
    fi
  fi

  if [ "$create_new_backup" = true ]; then
    # Create a backup with public key encryption
    if eval gpg --batch --no-options --no-tty --yes --recipient-file "$ENCRYPTION_GPG_KEYFILE_LOCATION" \
      -o "$BACKUP_FILE_ARCHIVE" --encrypt "$TEMP_BACKUP_ARCHIVE"; then
      info "Successfully created gpg (public key) encrypted backup $BACKUP_FILE_ARCHIVE"
      return 0
    else
      error "Encrypted backup failed! Maybe your key has expired or is invalid. You find the key details below.\n$(cat "$ENCRYPTION_GPG_KEYFILE_LOCATION" | gpg --import-options show-only --import)"
      return 1
    fi
  fi

  return 2
}

#######################################
# Function to create a backup with symmetric encryption
# Arguments:
#   None
# Returns:
#   0 if the backup was successful
#######################################
create_sym_encrypted_backup() {
  create_temporary_archive
  debug "Creating backup using passphrase"
  create_new_backup=true

  if [ "$BACKUP_USE_DEDUPE" = true ]; then
    if is_sym_key_changed || is_enc_mode_changed || is_backup_content_changed; then
      info "Changes detected since last backup (either key or backup content changed). Creating new backup file."
    else
      info "No changes detected since last backup. Dedupe enabled. No new backup file was created."
      create_new_backup=false
    fi
  fi

  # Create a backup with symmetric encryption
  if [ "$create_new_backup" = true ]; then
    debug "Creating backup with symmetric encryption"
    if gpg --batch --no-options --no-tty --yes --symmetric --passphrase "$ENCRYPTION_PASSWORD" \
      --cipher-algo "$ENCRYPTION_ALGORITHM" -o "$BACKUP_FILE_ARCHIVE" "$TEMP_BACKUP_ARCHIVE"; then
      info "Successfully created gpg (password) encrypted backup $BACKUP_FILE_ARCHIVE"
      return 0
    else
      error "Encrypted backup failed!"
      return 1
    fi
  fi

  return 2
}

#######################################
# Main function to backup database and
# additional data like attachments, sends, etc.
# Arguments:
#   None
# Returns:
#   None
#######################################
backup() {
  if [ "$ENCRYPTION_MODE" = "asymmetric" ]; then
    create_asym_encrypted_backup
    rc=$?
  elif [ "$ENCRYPTION_MODE" = "symmetric" ]; then
    create_sym_encrypted_backup
    rc=$?
  elif [ "$ENCRYPTION_MODE" = "none" ]; then
    create_simple_backup
    rc=$?
  fi

  if [ "$BACKUP_USE_DEDUPE" = true ] && [ "$rc" -eq 0 ]; then
    debug "Updating $BACKUP_INI after successful backup."
    update_config "last_backup_file" "$BACKUP_FILE_ARCHIVE"
    update_config "tarhash" "$("$BACKUP_HASHING_EXEC" "$BACKUP_FILE_ARCHIVE" | awk '{print $1}')"
    update_config "last_encryption_mode" "$ENCRYPTION_MODE"
  fi

  # Remove temporary files
  rm -rf "$TEMP_BACKUP_DIR"
  rm "$TEMP_BACKUP_ARCHIVE"
}

#######################################
# Performs a health check
# Arguments:
#   None
# Returns:
#   None
#######################################
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

#######################################
# Cleans up old backups after specified
# amount of time. Always keeps at least 1 backup.
# Arguments:
#   None
# Returns:
#   None
#######################################
cleanup() {
  if [ -n "$DELETE_AFTER" ] && [ "$DELETE_AFTER" -gt 0 ]; then
    if [ "$TIMESTAMP" != true ]; then warn "DELETE_AFTER will most likely have no effect because TIMESTAMP is not set to true."; fi
    newest_file=$(find "$BACKUP_DIR" -type f -regex "$BACKUP_FILE_REGEX" -exec stat -c "%Y %n" {} + | sort -n | tail -n 1 | cut -d " " -f 2-)
    find "$BACKUP_DIR" -type f -regex "$BACKUP_FILE_REGEX" -mtime +"$DELETE_AFTER" ! -path "$newest_file" -exec sh -c '
      . /opt/scripts/logging.sh

      rm -f $@
      info "Deleted backups after $DELETE_AFTER days: $@"
    ' shell {} \;
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
