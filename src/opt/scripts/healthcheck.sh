#!/bin/sh

ERROR_COUNT=`cat /logs/env.txt | grep error | cut -d"'" -f2`

if
[[ -f /data/db.sqlite3 ]] &&
[[ $ERROR_COUNT = '0' || ! -f /logs/env.txt ]]
then
    echo 0
    exit 0
else
    echo 1
    exit 1
fi