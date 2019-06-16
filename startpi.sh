#!/bin/bash
#
# start script for freeboard on a Raspberry Pi
#
#prefer jdk11, oracle jdk8, openjdk 8
if [ -d /usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt ]; then
	#Set JAVA_HOME for bellsoft jdk11
	export JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt
	echo "JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt" 2>&1
elif [ -d /usr/lib/jvm/jdk-11-bellsoft-aarch64 ]; then
	#Set JAVA_HOME for bellsoft jdk11 arm64
	export JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-aarch64
	echo "JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-aarch64" 2>&1
elif [ -d /usr/lib/jvm/java-11-openjdk-arm64 ]; then
	#Set JAVA_HOME for openjdk jdk11 arm64
	export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
	echo "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64" 2>&1
#elif [ -d /usr/lib/jvm/java-8-oracle ]; then
#	#Set JAVA_HOME for bellsoft jdk11
#	export JAVA_HOME=/usr/lib/jvm/java-8-oracle
#	echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" 2>&1
else
	export JAVA_HOME=`echo $(dirname $(dirname $(readlink -f $(which javac))))`
	echo "JAVA_HOME=$JAVA_HOME" 2>&1
fi
#SIGNALK_HOME=/home/pi/signalk-server
SIGNALK_HOME=`pwd`

#
cd $SIGNALK_HOME
mkdir -p signalk-static/logs

cd $SIGNALK_HOME
# archive the start.log 
mv signalk-static/logs/start.log signalk-static/logs/start.log.back

ARCH=`uname -m`
if echo "$ARCH" | grep '64'; then
	POM="-f pom64.xml"
else
	POM=""
fi

if [ -f ~/first_start ];then
    echo "Starting first time online: mvn $POM exec:java 2>&1" >signalk-static/logs/start.log 2>&1 
	rm ~/first_start
	mvn $POM exec:exec >>signalk-static/logs/start.log 2>&1
else
	echo "Starting offline: mvn -o $POM exec:exec 2>&1" >signalk-static/logs/start.log 2>&1 
	mvn -o $POM exec:exec >>signalk-static/logs/start.log 2>&1
fi