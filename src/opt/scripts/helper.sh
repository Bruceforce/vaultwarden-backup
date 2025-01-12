#!/bin/sh

# shellcheck disable=SC1091

. /opt/scripts/logging.sh
. /opt/scripts/set-env.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

#######################################
# Update config file
# Arguments:
#   $1 key to update
#   $2 value of the key
# Returns:
#   None
#######################################
update_config() {
    key="$1"
    new_value="$2"

    debug "key: $1"
    debug "new_value: $2"

    # Check if the key already exists in the configuration file

    if grep -q "^$key\s*=" "$BACKUP_INI"; then
        # Key exists, update the value
        sed -i "s@^\($key\s*=\s*\).*@\1$new_value@" "$BACKUP_INI"
    else
        # Key does not exist, add a new line
        echo "$key=$new_value" >> "$BACKUP_INI"
    fi
}


#######################################
# Source config file for dedupe mode
# Arguments:
#   None
# Returns:
#   None
#######################################
source_config() {
  debug "Sourcing ini file to get dedupe info."
  # shellcheck disable=SC1090
  if [ -f "$BACKUP_INI" ]; then
    . "$BACKUP_INI"
  else
    critical "Configuration file not found!"
  fi
}

#######################################
# Check if the encryption mode of the backup has changed.
# Arguments:
#   None
# Returns:
#   0 if the encryption mode of the backup has changed since last run
#   1 if not
#######################################
is_enc_mode_changed() {
  if [ "${last_encryption_mode:-UNDEFINED}" != "$ENCRYPTION_MODE" ]; then
    debug "Encryption mode changed. Returning 0"
    return 0
  fi

  return 1
}

#######################################
# Check if the content of the backup has changed.
# This is done by creating a hash of all files
# and hashing this again to make sure that there
# are no changes in existing files and also no new files were added.
# Arguments:
#   None
# Returns:
#   0 if the content of the backup has changed since last run
#   1 if not
#######################################
is_backup_content_changed() {
  if [ ! -f "${last_backup_file:-UNDEFINED}" ]; then
    debug "Unknown status of last backup. Returning 0"
    return 0
  fi

  # Calculate the hash of the latest stored backup file - this should never change unsless the file is corrupted
  latest_backup_tarhash=$("$BACKUP_HASHING_EXEC" "${last_backup_file:-UNDEFINED}" | awk '{print $1}' )
  # Calculates a hashes of all individual backup files in the temporary backup dir. Then calculates a single hash over all the hashes of the files.
  latest_backup_contenthash=$(find "$TEMP_BACKUP_DIR" -type f -exec "$BACKUP_HASHING_EXEC" {} \; | LC_ALL=C sort | "$BACKUP_HASHING_EXEC" | awk '{print $1}')

  debug "stored tarhash: ${tarhash:-UNDEFINED}"
  debug "latest tarhash: $latest_backup_tarhash"
  debug "stored contenthash: ${contenthash:-UNDEFINED}"
  debug "latest contenthash $latest_backup_contenthash"

  # If tar hashes differ return success (0) --> backed up archives have changed and might be corrupted
  if [ "$tarhash" != "$latest_backup_tarhash" ]; then
    debug "Backed up archives have changed and might be corrupted. Returning 0"
    return 0
  fi

  # If content hashes differ return success (0) --> files have changed
  if [ "$contenthash" != "$latest_backup_contenthash" ]; then
    debug "File contents changed. Returning 0"
    return 0
  fi

  debug "File contents have not changed. Returning 1"
  return 1
}

#######################################
# Check if the asymmetric key changed
# Arguments:
#   None
# Returns:
#   0 if the gpg asymmetric has changed since last run or no previous backup was found
#   1 if not
#######################################
is_asym_key_changed() {
  debug "Checking if gpg keys have changed."

  if [ ! -f "${last_backup_file:-UNDEFINED}" ]; then
    debug "Unknown status of last backup. Returning 0"
    return 0
  fi

  # Get KeyID of current GPG Keyfile
  current_keyID="$(gpg --with-colons "$ENCRYPTION_GPG_KEYFILE_LOCATION" 2>&1 | awk -F':' '/sub/{ print $5 }')"

  # Get public KeyID of previous backup
  previous_keyID="$(gpg --pinentry-mode cancel --list-packets "${last_backup_file:-UNDEFINED}" 2>&1 | sed -n 's/.*:pubkey\s.*\skeyid \(.*\)$/\1/p')"

  # Check if the key IDs match.
  if [ "$current_keyID" != "$previous_keyID" ]; then
    debug "gpg keys have changed. Returning 0"
    return 0; fi

  debug "gpg keys have not changed. Returning 1"
  return 1
}

#######################################
# Check if the symmetric key changed
# Arguments:
#   None
# Returns:
#   0 if the key has changed since last run or no previous backup was found
#   1 if not
#######################################
is_sym_key_changed() {
  debug "Checking if symmetric key has changed."

  if [ ! -f "${last_backup_file:-UNDEFINED}" ]; then
    debug "Unknown status of last backup. Returning 0"
    return 0
  fi

  # Attempt to decrypt previous backup with current key
  if gpg --decrypt --batch --dry-run --output /dev/null --passphrase "$ENCRYPTION_PASSWORD" "${last_backup_file:-UNDEFINED}" > /dev/null 2>&1; then
    # Previous backup key is correct
    debug "Passphrase is unchanged. Returning 1"
    return 1
  else
    debug "Passphrase has changed since the last backup! Returning 0"
    return 0
  fi
}
