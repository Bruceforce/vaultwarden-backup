ARG ARCH=
FROM ${ARCH}alpine:latest

RUN apk add --no-cache \
    sqlite \
    busybox-suid \
    su-exec \
    tzdata \
    tar \
    xz \
    gpg \
    gpg-agent

COPY src /

HEALTHCHECK CMD [ "healthcheck.sh" ]

ENTRYPOINT ["entrypoint.sh"]
