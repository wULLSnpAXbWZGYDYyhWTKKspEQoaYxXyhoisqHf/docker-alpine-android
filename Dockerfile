# syntax=docker/dockerfile:1.3
# refs:
#   https://docs.docker.com/develop/develop-images/build_enhancements/#overriding-default-frontends
#   https://pythonspeed.com/articles/docker-buildkit/

FROM docker.io/frolvlad/alpine-java:jdk8-full as build
ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://git.dotya.ml/wanderer/docker-alpine-android.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.license=GPL-3.0 \
      org.label-schema.vendor="wanderer <wanderer at git.dotya.ml>"

ENV VERSION_SDK_TOOLS "3859397"
ENV VERSION_TOOLS "6609375"

ENV ANDROID_HOME "/tmp/sdk"
ENV ANDROID_SDK_ROOT "${ANDROID_HOME}"

WORKDIR /tmp
RUN apk update && \
    apk add --no-cache binutils ca-certificates curl git openssl unzip --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing && \
    \
    curl -o sdk.zip -s https://dl.google.com/android/repository/sdk-tools-linux-"${VERSION_SDK_TOOLS}".zip && \
    unzip ./sdk.zip -d "${ANDROID_HOME}" && \
    rm -f ./sdk.zip && \
    \
    curl -o tools.zip -s https://dl.google.com/android/repository/commandlinetools-linux-"${VERSION_TOOLS}"_latest.zip \
 && mkdir -p "${ANDROID_HOME}"/cmdline-tools \
 && unzip ./tools.zip -d "${ANDROID_HOME}"/cmdline-tools \
 && rm -v ./tools.zip && \
 \
 mkdir -p $ANDROID_HOME/licenses/ \
 && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
 && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license \
 && yes | ${ANDROID_HOME}/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} --licenses >/dev/null

COPY packages.txt "${ANDROID_HOME}"
RUN mkdir -p /"$(whoami)"/.android && \
    touch /"$(whoami)"/.android/repositories.cfg && \
    \
    yes | "${ANDROID_HOME}"/tools/bin/sdkmanager --verbose --licenses && \
    "${ANDROID_HOME}"/tools/bin/sdkmanager --verbose --update && \
    \
    while read -r package; do PACKAGES="${PACKAGES}${package} "; done < "${ANDROID_HOME}"/packages.txt && ${ANDROID_HOME}/tools/bin/sdkmanager --verbose ${PACKAGES}

FROM docker.io/adoptopenjdk/openjdk11:alpine-slim
COPY --from=build /tmp/sdk /sdk

# Makes JVM aware of memory limit available to the container (cgroups)
ENV JAVA_OPTS='-XX:+UseContainerSupport -XX:MaxRAMPercentage=80'

ENV ANDROID_HOME "/sdk"
ENV ANDROID_SDK_ROOT "${ANDROID_HOME}"
ENV PATH "$PATH:${ANDROID_HOME}/tools"
ENV ASDF_VERSION "v0.8.1"
ENV GRADLE_VERSION "7.1"

RUN apk add --no-cache bash curl git vim xz --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    && git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "${ASDF_VERSION}" \
    && sed -i 's/\/bin\/ash/\/bin\/bash/' /etc/passwd && cat /etc/passwd \
    && echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc \
    && echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc \
    && bash -c ". ~/.bashrc; ~/.asdf/bin/asdf plugin-add gradle https://github.com/rfrancis/asdf-gradle.git" \
    && bash -c ". ~/.bashrc; ~/.asdf/bin/asdf install gradle ${GRADLE_VERSION}" \
    && bash -c ". ~/.bashrc; ~/.asdf/bin/asdf global gradle ${GRADLE_VERSION}" \
    && bash -c ". ~/.bashrc; ~/.asdf/shims/gradle --version" && \
    \
    ln -svf /bin/bash /bin/sh \
    && ls -la /bin/*sh \
    && echo -e "\n. ~/.bashrc" >> ~/.bash_profile

# as per https://github.com/LennonRuangjaroon/alpine-java8-jdk#--remove-spurious-folders-not-needed-like-jrelib
RUN rm -rf /opt/jre/lib/plugin.jar \
     /opt/jre/lib/ext/jfxrt.jar \
     /opt/jre/bin/javaws \
     /opt/jre/lib/javaws.jar \
     /opt/jre/lib/desktop \
     /opt/jre/plugin \
     /opt/jre/lib/deploy* \
     /opt/jre/lib/*javafx* \
     /opt/jre/lib/*jfx* \
     /opt/jre/lib/amd64/libdecora_sse.so \
     /opt/jre/lib/amd64/libprism_*.so \
     /opt/jre/lib/amd64/libfxplugins.so \
     /opt/jre/lib/amd64/libglass.so \
     /opt/jre/lib/amd64/libgstreamer-lite.so \
     /opt/jre/lib/amd64/libjavafx*.so \
     /opt/jre/lib/amd64/libjfx*.so &&\
  rm -rf /var/cache/apk/*

WORKDIR /
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
