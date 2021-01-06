FROM frolvlad/alpine-java:jdk8-full as build
MAINTAINER wanderer <wanderer at git.dotya.ml>

ENV VERSION_SDK_TOOLS "3859397"
ENV VERSION_TOOLS "6609375"

ENV ANDROID_HOME "/tmp/sdk"
ENV ANDROID_SDK_ROOT "${ANDROID_HOME}"

RUN apk update
RUN apk add --no-cache bash binutils ca-certificates curl git openssl unzip vim xz --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

WORKDIR /tmp
RUN curl -o sdk.zip -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip
RUN unzip ./sdk.zip -d ${ANDROID_SDK_ROOT}
RUN rm -f ./sdk.zip

RUN curl -o tools.zip -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip \
 && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
 && unzip ./tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
 && rm -v ./tools.zip

RUN mkdir -p $ANDROID_SDK_ROOT/licenses/ \
 && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK_ROOT/licenses/android-sdk-license \
 && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_SDK_ROOT/licenses/android-sdk-preview-license \
 && yes | ${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses >/dev/null

ADD packages.txt ${ANDROID_SDK_ROOT}
RUN mkdir -p /$(whoami)/.android
RUN touch /$(whoami)/.android/repositories.cfg

RUN yes | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager --licenses
RUN ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < ${ANDROID_SDK_ROOT}/packages.txt && ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager ${PACKAGES}

FROM adoptopenjdk/openjdk11:alpine-slim
COPY --from=build /tmp/sdk /sdk
ENV ANDROID_HOME "/sdk"
ENV ANDROID_SDK_ROOT "${ANDROID_SDK_ROOT}"
ENV PATH "$PATH:${ANDROID_SDK_ROOT}/tools:${ANDROID_HOME}/tools"

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
