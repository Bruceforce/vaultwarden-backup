FROM alpine:latest

RUN apk add --update \
    sqlite

COPY start.sh backup.sh /

ENV DB_FILE /data/db.sqlite3
ENV BACKUP_FILE /data/db-backup.sqlite3
ENV CRON_TIME "* * * * *"

RUN chmod 700 /start.sh /backup.sh

CMD /start.sh

