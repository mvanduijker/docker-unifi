# :: Header
  FROM ubuntu:20.04
  ENV DEBIAN_FRONTEND=noninteractive
  ENV APP_NAME="unifi"
  ENV APP_VERSION="8.0.28"
  ENV APP_ROOT="/unifi"

# :: Run
  USER root

  # :: update image
    RUN set -ex; \
      apt update -y; \
      apt upgrade -y;

  # :: prepare image
    RUN set -ex; \
      mkdir -p ${APP_ROOT};

  # https://community.ui.com/RELEASES UniFi Network Application
    ADD https://dl.ui.com/unifi/${APP_VERSION}/unifi_sysvinit_all.deb /tmp/unifi.deb

    RUN set -ex; \
      apt install -y \
        mongodb=1:3.6.9+really3.6.8+90~g8e540c0b6d-0ubuntu5 \
        openjdk-17-jre-headless \
        binutils \
        jsvc \
        curl \
        libcap2 \
        liblog4j2-java \
        tzdata \
        gosu \
        logrotate;

    RUN set -ex; \
      dpkg -i /tmp/unifi.deb; \
      ln -s /var/lib/unifi ${APP_ROOT}/var; \
      ln -s /var/log/unifi ${APP_ROOT}/log; \
      mkdir -p ${APP_ROOT}/var/sites/default;

  # :: copy root filesystem changes and add execution rights to init scripts
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin

  # :: set uid/gid to 1000:1000 for existing user
    RUN set -ex; \
      NOROOT_USER="unifi" \
      NOROOT_UID="$(id -u ${NOROOT_USER})"; \
      NOROOT_GID="$(id -g ${NOROOT_USER})"; \
      find / -not -path "/proc/*" -user ${NOROOT_UID} -exec chown -h -R 1000:1000 {} \;;\
      find / -not -path "/proc/*" -group ${NOROOT_GID} -exec chown -h -R 1000:1000 {} \;; \
      usermod -u 1000 ${NOROOT_USER}; \
      groupmod -g 1000 ${NOROOT_USER}; \
      usermod -l docker ${NOROOT_USER}; \
      groupmod -n docker ${NOROOT_USER};

  # :: change home path for existing user and set correct permission
    RUN set -ex; \
      usermod -d ${APP_ROOT} docker; \
      chown -R 1000:1000 \
        ${APP_ROOT} \
        /usr/lib/unifi \
        /var/run/unifi \
        /var/lib/unifi \
        /var/log/unifi;

# :: Volumes
  VOLUME ["${APP_ROOT}/var"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER docker
  ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]