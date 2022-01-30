ARG ARCH=
FROM ${ARCH}alpine:latest

RUN apk add --no-cache \
    sqlite \
    busybox-suid \
    su-exec \
    tzdata

COPY src /

ENTRYPOINT ["entrypoint.sh"]
