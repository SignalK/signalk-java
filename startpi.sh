#!/bin/bash
#
# start script for freeboard on a Raspberry Pi
#
#prefer jdk11, oracle jdk8, openjdk 8
if [ -d /usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt ]; then
	#Set JAVA_HOME for bellsoft jdk11
	export JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt
	echo "JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt" 2>&1
elif [ -d /usr/lib/jvm/java-8-oracle ]; then
	#Set JAVA_HOME for bellsoft jdk11
	export JAVA_HOME=/usr/lib/jvm/java-8-oracle
	echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" 2>&1
else
	export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-armhf
	echo "JAVA_HOME=/usr/lib/jvm/java-8-openjdk-armhf" 2>&1
fi
#SIGNALK_HOME=/home/pi/signalk-server
SIGNALK_HOME=`pwd`

#
cd $SIGNALK_HOME
mkdir -p signalk-static/logs

# jolokia
#JOLOKIA="-javaagent:./hawtio/jolokia-jvm-1.6.0-agent.jar=config=./conf/jolokia.conf"
#EXT="-Djava.util.Arrays.useLegacyMergeSort=true"
#MEM="-Xmx256m -XX:+HeapDumpOnOutOfMemoryError -Dio.netty.leakDetection.level=ADVANCED -XX:+UseParallelGC -XX:+AggressiveOpts"
#HAWTIO=-Dhawtio.authenticationEnabled=false
#LOG4J=-Dlog4j.configuration=file://$SIGNALK_HOME/conf/log4j2.json

cd $SIGNALK_HOME
# archive the start.log 
mv signalk-static/logs/start.log signalk-static/logs/start.log.back

if [ -f ~/first_start ];then
    echo "Starting first time online: mvn exec:java 2>&1" >signalk-static/logs/start.log 2>&1 
	rm ~/first_start
	mvn exec:exec >>signalk-static/logs/start.log 2>&1
else
	echo "Starting offline: mvn -o exec:exec 2>&1" >signalk-static/logs/start.log 2>&1 
	mvn -o  exec:exec >>signalk-static/logs/start.log 2>&1
fi