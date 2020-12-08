FROM alpine:latest

ARG USER=notroot
ARG GROUP=notroot
ARG UID=1000
ARG GID=1000

COPY alpine_information.sh /alpine_information.sh
COPY check_is_upgrade_needed.sh /check_is_upgrade_needed.sh
RUN chmod +x /alpine_information.sh && \
    chmod +x /check_is_upgrade_needed.sh && \
    apk upgrade --no-cache && \
    addgroup -g ${GID} -S ${GROUP} && \
    adduser -u ${UID} -S -D ${USER} ${GROUP}

WORKDIR /home/${USER}
USER ${USER}