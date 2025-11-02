ARG ARCH=
FROM ${ARCH}alpine:3.22.2@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412

RUN apk add --no-cache \
    sqlite \
    busybox-suid \
    su-exec \
    tzdata \
    xz \
    gpg \
    gpg-agent

COPY src /

HEALTHCHECK CMD [ "healthcheck.sh" ]

ENTRYPOINT ["entrypoint.sh"]
