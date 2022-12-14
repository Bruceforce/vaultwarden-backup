#!/bin/sh

ERROR_COUNT=`cat $LOG_DIR/env.txt | grep error | cut -d"'" -f2`

if
[[ ! -f $VW_DATABASE_URL ]]
then
    echo "Database not found!"
    exit 1
fi

if
[[ ! $ERROR_COUNT = '0' ]]
then
    echo "error_count: $ERROR_COUNT"
    exit 1
fi

exit 0