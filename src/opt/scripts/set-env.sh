#!/bin/sh

# shellcheck disable=SC1091

export LOG_LEVEL="${LOG_LEVEL:-INFO}"
. /opt/scripts/logging.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

# Functions
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

check_deprecations

# Set default environment variables
# Environment variables specific to this image
export BACKUP_DIR="${BACKUP_DIR:-/backup}"
export BACKUP_DIR_PERMISSIONS="${BACKUP_DIR_PERMISSIONS:-700}"
export CRON_TIME="${CRON_TIME:-0 5 * * *}"
export TIMESTAMP="${TIMESTAMP:-false}"
export UID="${UID:-100}"
export GID="${GID:-100}"
export CRONFILE="${CRONFILE:-/etc/crontabs/root}"
export LOG_DIR="${LOG_DIR:-/app/log}"
export LOG_DIR_PERMISSIONS="${LOG_DIR_PERMISSIONS:-777}"
export LOGFILE_APP="${LOGFILE_APP:-$LOG_DIR/app.log}"
export LOGFILE_CRON="${LOGFILE_CRON:-$LOG_DIR/cron.log}"
export DELETE_AFTER="${DELETE_AFTER:-0}"
export VW_BACKUP_VERSION="0.0.0-dev"

# Additional backup files
export BACKUP_ADD_DATABASE="${BACKUP_ADD_DATABASE:-true}"
export BACKUP_ADD_ATTACHMENTS="${BACKUP_ADD_ATTACHMENTS:-true}"
export BACKUP_ADD_CONFIG_JSON="${BACKUP_ADD_CONFIG_JSON:-true}"
export BACKUP_ADD_ICON_CACHE="${BACKUP_ADD_ICON_CACHE:-false}"
export BACKUP_ADD_RSA_KEY="${BACKUP_ADD_RSA_KEY:-true}"
export BACKUP_ADD_SENDS="${BACKUP_ADD_SENDS:-false}"

# Vaultwarden file locations
# Defaulting to <https://github.com/dani-garcia/vaultwarden/wiki/Changing-persistent-data-location>
export VW_DATA_FOLDER="${VW_DATA_FOLDER:-/data}"
export VW_DATABASE_URL="${VW_DATABASE_URL:-$VW_DATA_FOLDER/db.sqlite3}"
export VW_ATTACHMENTS_FOLDER="${VW_ATTACHMENTS_FOLDER:-$VW_DATA_FOLDER/attachments}"
export VW_ICON_CACHE_FOLDER="${VW_ICON_CACHE_FOLDER:-$VW_DATA_FOLDER/icon_cache}"