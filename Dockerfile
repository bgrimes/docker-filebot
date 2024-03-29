FROM openjdk:11.0-jre

# install shell2http
COPY --from=msoap/shell2http /app/shell2http /app/shell2http

# install filebot
ENV FILEBOT_VERSION 4.8.5

WORKDIR /usr/share/filebot

ARG FILEBOT_SHA256="13ea4db2f744e0280f4cc2972ae53ade86328062c9b02f170470d8dc7a0ebb17"
ARG FILEBOT_PACKAGE="FileBot_${FILEBOT_VERSION}_amd64.deb"
COPY ${FILEBOT_PACKAGE} ./
RUN echo "$FILEBOT_SHA256 *$FILEBOT_PACKAGE" | sha256sum --check --strict \
 && dpkg -i $FILEBOT_PACKAGE \
 && rm $FILEBOT_PACKAGE

RUN apt-get update && apt-get install -y \
    mediainfo \
    libchromaprint-tools \
    file \
    curl \
    inotify-tools \
 && rm -rf /var/lib/apt/lists/*

ENV DOCKER_DATA /data
WORKDIR $DOCKER_DATA
ENV HOME $DOCKER_DATA
ENV JAVA_OPTS "-DuseGVFS=false -Djava.net.useSystemProxies=false -Dapplication.deployment=docker -Dapplication.dir=$DOCKER_DATA -Duser.home=$DOCKER_DATA -Djava.io.tmpdir=$DOCKER_DATA/tmp -Djava.util.prefs.PreferencesFactory=net.filebot.util.prefs.FilePreferencesFactory -Dnet.filebot.util.prefs.file=$DOCKER_DATA/prefs.properties"

# install s6 overlay
ARG OVERLAY_VERSION="v1.22.0.0"
ARG OVERLAY_ARCH="amd64"

RUN \
  curl -o \
  /tmp/s6-overlay.tar.gz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" && \
  tar xfz \
    /tmp/s6-overlay.tar.gz -C / && \
  echo "**** create abc user and make our folders ****" && \
  useradd -u 911 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  mkdir -p \
  /app \
  /config \
  /defaults && \
  echo "**** cleanup ****" && \
  apt-get clean

# initialize filebot and clean up some permissions
RUN \
  filebot -script fn:sysinfo && \
  mkdir -p ${DOCKER_DATA}/.filebot && \
  ln -s ${DOCKER_DATA}/cache/ ${DOCKER_DATA}/.filebot/ && \
  ls -lah ${DOCKER_DATA}

COPY root/ /

ENTRYPOINT ["/init"]
