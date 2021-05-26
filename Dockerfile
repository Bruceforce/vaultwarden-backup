ARG ARCH=
FROM ${ARCH}alpine:latest

RUN addgroup -S app && adduser -S -G app app

RUN apk add --no-cache \
    busybox-suid \
    su-exec \
    zip \
    tzdata

ENV CRON_TIME "0 5 * * *"
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

ENTRYPOINT ["entrypoint.sh"]
