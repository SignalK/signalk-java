FROM ubuntu:18.04

RUN apt-get update && apt-get upgrade --yes && apt-get --yes install \
    apt-utils \
    curl \
    gnupg \
    wget

RUN ["wget", "https://dl.influxdata.com/influxdb/releases/influxdb_1.7.4_amd64.deb"]
RUN ["dpkg", "-i", "influxdb_1.7.4_amd64.deb"]