#!/bin/sh

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