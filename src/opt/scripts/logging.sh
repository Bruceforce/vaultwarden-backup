#!/bin/sh

### Vars ###
warning_counter=0
error_counter=0

# Set LOG_LEVEL
if [ "$LOG_LEVEL" = "DEBUG" ]; then LOG_LEVEL_NUMBER=7; fi
if [ "$LOG_LEVEL" = "INFO" ]; then LOG_LEVEL_NUMBER=6; fi
if [ "$LOG_LEVEL" = "WARN" ]; then LOG_LEVEL_NUMBER=4; fi
if [ "$LOG_LEVEL" = "ERROR" ]; then LOG_LEVEL_NUMBER=3; fi
if [ "$LOG_LEVEL" = "CRITICAL" ]; then LOG_LEVEL_NUMBER=2; fi

### Functions ###

# General log format
log() {
  printf "$(date "+%F %T") - %b\n" "$*" >> "$LOGFILE_APP"
}

# Debug log
debug() {
  if [ "$LOG_LEVEL_NUMBER" -eq 7 ]; then
    log "DEBUG - $*"
  fi
}

# Info log
info() {
  if [ "$LOG_LEVEL_NUMBER" -ge 6 ]; then
    log "INFO - $*"
  fi
}

# Warning log
warn() {
  warning_counter=$((warning_counter + 1))
  if [ "$LOG_LEVEL_NUMBER" -ge 4 ]; then
    log "WARNING - $*"
  fi
  debug "The new warning counter is $warning_counter."
}

# Error log
error() {
  error_counter=$((error_counter + 1))
  if [ "$LOG_LEVEL_NUMBER" -ge 3 ]; then
    log "ERROR - $*" 1>&2
  fi
  debug "The new error counter is $error_counter."
}

# Critical log
critical() {
  error_counter=$((error_counter + 1))
  if [ "$LOG_LEVEL_NUMBER" -ge 2 ]; then
    log "CRITICAL - $*\nExiting"
  fi
  debug "The new error counter is $error_counter."
  cat "$LOGFILE_APP"
  exit 1
}
