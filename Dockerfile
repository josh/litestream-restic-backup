ARG LITESTREAM_VERSION=0.5.12
ARG RESTIC_VERSION=0.19.0
ARG RESTIC_AGE_KEY_VERSION=1.1.3
ARG AGE_VERSION=1.3.1


FROM alpine:3.22@sha256:310c62b5e7ca5b08167e4384c68db0fd2905dd9c7493756d356e893909057601 AS tools

ARG LITESTREAM_VERSION
ARG RESTIC_VERSION
ARG RESTIC_AGE_KEY_VERSION
ARG AGE_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl

WORKDIR /out

RUN set -o errexit -o nounset; \
    case "$TARGETARCH" in \
      amd64) arch=x86_64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl --fail --silent --show-error --location --output litestream.tar.gz \
      "https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-${LITESTREAM_VERSION}-linux-${arch}.tar.gz"; \
    tar --extract --gzip --file litestream.tar.gz litestream; \
    chmod 0755 litestream; \
    rm litestream.tar.gz

RUN set -o errexit; \
    curl --fail --silent --show-error --location --output restic.bz2 \
      "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${TARGETARCH}.bz2"; \
    bunzip2 restic.bz2; \
    chmod 0755 restic

RUN set -o errexit; \
    curl --fail --silent --show-error --location --output age.tar.gz \
      "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${TARGETARCH}.tar.gz"; \
    tar --extract --gzip --file age.tar.gz --strip-components=1 --directory . age/age; \
    chmod 0755 age; \
    rm age.tar.gz

RUN set -o errexit; \
    curl --fail --silent --show-error --location --output restic-age-key.tar.gz \
      "https://github.com/josh/restic-age-key/releases/download/v${RESTIC_AGE_KEY_VERSION}/restic-age-key-v${RESTIC_AGE_KEY_VERSION}-linux-${TARGETARCH}.tar.gz"; \
    tar --extract --gzip --file restic-age-key.tar.gz --strip-components=1 --directory . restic-age-key/restic-age-key; \
    chmod 0755 restic-age-key; \
    rm restic-age-key.tar.gz


FROM alpine:3.22@sha256:310c62b5e7ca5b08167e4384c68db0fd2905dd9c7493756d356e893909057601

LABEL org.opencontainers.image.title="litestream-restic-backup" \
      org.opencontainers.image.source="https://github.com/joshpeek/litestream-restic-backup"

RUN apk add --no-cache ca-certificates

COPY --from=tools /out/litestream     /usr/local/bin/litestream
COPY --from=tools /out/restic         /usr/local/bin/restic
COPY --from=tools /out/restic-age-key /usr/local/bin/restic-age-key
COPY --from=tools /out/age            /usr/local/bin/age

RUN adduser -D -H -u 65532 -s /sbin/nologin backup \
 && mkdir --parents /work \
 && chown backup:backup /work

USER 65532:65532
ENV TMPDIR=/work \
    RESTIC_CACHE_DIR=/work/.restic-cache
WORKDIR /work
