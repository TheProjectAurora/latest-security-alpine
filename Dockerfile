FROM alpine:latest

ARG USER=notroot
ARG GROUP=notroot
ARG UID=1000
ARG GID=1000

COPY alpine_information.sh /alpine_information.sh
RUN chmod +x /alpine_information.sh && \
    apk upgrade --no-cache && \
    addgroup -g ${GID} -S ${GROUP} && \
    adduser -u ${UID} -S -D ${USER} ${GROUP}

WORKDIR /home/${USER}
USER ${USER}