#!/bin/sh

#set -xe

if [ $# -ne 1 ]; then exit 1; fi

NEW_VERSION=$1

sed -Ei "s/(^export VW_BACKUP_VERSION=).*/\1${NEW_VERSION}/" src/opt/scripts/set-env.sh