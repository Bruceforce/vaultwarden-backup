FROM alpine:latest

RUN addgroup -S app && adduser -S -G app app

RUN apk add --no-cache \
    sqlite \
    busybox-suid \
    su-exec

ENV DB_FILE /data/db.sqlite3
ENV BACKUP_FILE /data/db_backup/backup.sqlite3
ENV BACKUP_FILE_PERMISSIONS 600
ENV CRON_TIME "0 5 * * *"
ENV TIMESTAMP false
ENV UID 100
ENV GID 100
ENV CRONFILE /etc/crontabs/root
ENV LOGFILE /app/log/backup.log
ENV DELETE_AFTER 0

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /app/

RUN mkdir /app/log/ \
    && chown -R app:app /app/ \
    && chmod -R 777 /app/ \
    && chmod +x /usr/local/bin/entrypoint.sh 
#    && echo "\$CRON_TIME \$BACKUP_CMD >> \$LOGFILE 2>&1" | crontab -

ENTRYPOINT ["entrypoint.sh"]
