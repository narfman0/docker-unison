FROM alpine:3.7
MAINTAINER Jon Robison <narfman0@blastedstudios.com>

ARG UNISON_VERSION=2.48.15v4

# Install in one run so that build tools won't remain in any docker layers
# Install build tools
RUN apk add --update build-base curl bash su-exec tini ocaml

# Download & Install Unison
RUN curl -L https://github.com/bcpierce00/unison/archive/v$UNISON_VERSION.tar.gz | tar zxv -C /tmp && \
    cd /tmp/unison-${UNISON_VERSION} && \
    sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' src/fsmonitor/linux/inotify_stubs.c && \
    make && \
    cp src/unison src/unison-fsmonitor /usr/local/bin

# Remove build tools
RUN apk del build-base curl ocaml && \
    # Remove tmp files and caches
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/unison-${UNISON_VERSION} && \
    deluser xfs

# These can be overridden later
ENV TZ="America/New_York" \
    LANG="C.UTF-8" \
    UNISON_DIR="/data" \
    HOME="/tmp" \
    ##
    # Use 1000:1001 as default user
    ##
    UNISON_USER="unison" \
    UNISON_GROUP="sync" \
    UNISON_UID="1000" \
    UNISON_GID="1001"


# Install unison server script
COPY entrypoint.sh /entrypoint.sh

VOLUME /unison

EXPOSE 5000
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
