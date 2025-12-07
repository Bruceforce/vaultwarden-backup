ARG ARCH=
FROM ${ARCH}alpine:3.23.0@sha256:51183f2cfa6320055da30872f211093f9ff1d3cf06f39a0bdb212314c5dc7375

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
