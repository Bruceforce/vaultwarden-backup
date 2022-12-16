#!/bin/sh

if [ ! -f /tmp/health ]; then
    install -d /tmp
    printf 0 > /tmp/health
fi

exit "$(cat /tmp/health)"