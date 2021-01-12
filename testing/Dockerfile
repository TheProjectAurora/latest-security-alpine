FROM alpine:3.12.1

ARG USER=notroot
ARG GROUP=notroot
ARG UID=1000
ARG GID=1000

COPY check_is_upgrade_needed.sh /check_is_upgrade_needed.sh
RUN chmod +x /check_is_upgrade_needed.sh && \
    addgroup -g ${GID} -S ${GROUP} && \
    adduser -u ${UID} -S -D ${USER} ${GROUP}

WORKDIR /home/${USER}
USER ${USER}