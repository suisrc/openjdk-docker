FROM debian:buster

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata curl ca-certificates fontconfig locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk-17.0.3_7_openj9-0.32.0

COPY slim-java* /usr/local/bin/

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       amd64|x86_64) \
         ESUM='7dca04533d539675cc22d60d567b660bbf9a5a8c6ce832a189caea753590bbdd'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/semeru17-binaries/releases/download/jdk-17.0.3%2B7_openj9-0.32.0/ibm-semeru-open-jdk_x64_linux_17.0.3_7_openj9-0.32.0.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    export PATH="/opt/java/openjdk/bin:$PATH"; \
    apt-get update; apt-get install -y --no-install-recommends binutils; \
    /usr/local/bin/slim-java.sh /opt/java/openjdk; \
    apt-get remove -y binutils; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"

#ENV JAVA_TOOL_OPTIONS="-XX:+IgnoreUnrecognizedVMOptions -XX:+IdleTuningGcOnIdle -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,readonly,nonFatal"

# Create OpenJ9 SharedClassCache (SCC) for bootclasses to improve the java startup.
# Downloads and runs tomcat to generate SCC for bootclasses at /opt/java/.scc/openj9_system_scc
# Does a dry-run and calculates the optimal cache size and recreates the cache with the appropriate size.
# With SCC, OpenJ9 startup is improved ~50% with an increase in image size of ~14MB
# Application classes can be create a separate cache layer with this as the base for further startup improvement

#RUN set -eux; \
#    unset OPENJ9_JAVA_OPTIONS; \
#    SCC_SIZE="50m"; \
#    DOWNLOAD_PATH_TOMCAT=/tmp/tomcat; \
#    INSTALL_PATH_TOMCAT=/opt/tomcat-home; \
#    TOMCAT_CHECKSUM="0db27185d9fc3174f2c670f814df3dda8a008b89d1a38a5d96cbbe119767ebfb1cf0bce956b27954aee9be19c4a7b91f2579d967932207976322033a86075f98"; \
#    TOMCAT_DWNLD_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz"; \
#    \
#    mkdir -p "${DOWNLOAD_PATH_TOMCAT}" "${INSTALL_PATH_TOMCAT}"; \
#    curl -LfsSo "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz "${TOMCAT_DWNLD_URL}"; \
#    echo "${TOMCAT_CHECKSUM} *${DOWNLOAD_PATH_TOMCAT}/tomcat.tar.gz" | sha512sum -c -; \
#    tar -xf "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz -C "${INSTALL_PATH_TOMCAT}" --strip-components=1; \
#    rm -rf "${DOWNLOAD_PATH_TOMCAT}"; \
#    \
#    java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version; \
#    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"; \
#    "${INSTALL_PATH_TOMCAT}"/bin/startup.sh; \
#    sleep 5; \
#    "${INSTALL_PATH_TOMCAT}"/bin/shutdown.sh -force; \
#    sleep 15; \
#    FULL=$( (java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,printallStats 2>&1 || true) | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}'); \
#    DST_CACHE=$(java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,destroy 2>&1 || true); \
#    SCC_SIZE=$(echo $SCC_SIZE | sed 's/.$//'); \
#    SCC_SIZE=$(awk "BEGIN {print int($SCC_SIZE * $FULL / 100.0)}"); \
#    [ "${SCC_SIZE}" -eq 0 ] && SCC_SIZE=1; \
#    SCC_SIZE="${SCC_SIZE}m"; \
#    java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version; \
#    unset OPENJ9_JAVA_OPTIONS; \
#    \
#    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"; \
#    "${INSTALL_PATH_TOMCAT}"/bin/startup.sh; \
#    sleep 5; \
#    "${INSTALL_PATH_TOMCAT}"/bin/shutdown.sh -force; \
#    sleep 5; \
#    FULL=$( (java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,printallStats 2>&1 || true) | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}'); \
#    echo "SCC layer is $FULL% full."; \
#    rm -rf "${INSTALL_PATH_TOMCAT}"; \
#    if [ -d "/opt/java/.scc" ]; then \
#          chmod -R 0777 /opt/java/.scc; \
#    fi; \
#    \
#    echo "SCC generation phase completed";

CMD ["jshell"]