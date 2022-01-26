ARG ARCH=
FROM ${ARCH}alpine:latest

RUN addgroup -S app && adduser -S -G app app

RUN apk add --no-cache \
    sqlite \
    busybox-suid \
    su-exec \
    tzdata

COPY src /

# RUN mkdir /app/log/ \
#     && chown -R app:app /app/ \
#     && chmod -R 777 /app/ \
#     && chmod +x /usr/local/bin/entrypoint.sh 
#    && echo "\$CRON_TIME \$BACKUP_CMD >> \$LOGFILE 2>&1" | crontab -

ENTRYPOINT ["entrypoint.sh"]
