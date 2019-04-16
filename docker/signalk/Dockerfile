FROM ubuntu:18.04

RUN apt-get update && apt-get upgrade --yes && apt-get --yes install \
    apt-utils \
    less \
    net-tools \
    emacs \
    openjdk-11-jdk \
    maven \
    git \
    curl \
    gnupg \
    wget

RUN ["mkdir", "/etc/signalkJavaServer"]
COPY ["docker/signalk/signalk_entrypoint.sh", "/signalk_entrypoint.sh"]

ENTRYPOINT ["/signalk_entrypoint.sh"]
CMD ["/bin/bash"]