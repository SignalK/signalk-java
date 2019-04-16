#!/bin/bash
set -e

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))

# start signalk
cd /etc/signalkJavaServer
mvn exec:exec
