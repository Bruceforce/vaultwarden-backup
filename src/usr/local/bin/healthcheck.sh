#!/bin/sh

# shellcheck disable=SC1091

. /opt/scripts/set-env.sh

if [ ! -f "$HEALTHCHECK_FILE" ]; then
    printf 0 > "$HEALTHCHECK_FILE"
fi

exit "$(cat "$HEALTHCHECK_FILE")"