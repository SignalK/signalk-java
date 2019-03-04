#!/bin/bash
#
# start script for freeboard on a Raspberry Pi
#
#Set JAVA_HOME for bellsoft jdk11
export JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt
#SIGNALK_HOME=/home/pi/signalk-server
SIGNALK_HOME=`pwd`

#
cd $SIGNALK_HOME
mkdir -p signalk-static/logs

# jolokia
JOLOKIA="-javaagent:./hawtio/jolokia-jvm-1.6.0-agent.jar=config=./conf/jolokia.conf"
EXT="-Djava.util.Arrays.useLegacyMergeSort=true"
MEM="-Xmx128m -XX:+HeapDumpOnOutOfMemoryError -Dio.netty.leakDetection.level=ADVANCED -XX:+UseParallelGC -XX:+AggressiveOpts"
HAWTIO=-Dhawtio.authenticationEnabled=false
LOG4J=-Dlog4j.configuration=file://$SIGNALK_HOME/conf/log4j2.json

cd $SIGNALK_HOME
# archive the start.log 
mv signalk-static/logs/start.log signalk-static/logs/start.log.back
#mvn $EXT $LOG4J exec:java 2>&1 &" >>signalk-static/logs/start.log 2>&1 &
#mvn $EXT $LOG4J exec:java 
#>>logs/start.log 2>&1 &
echo "Starting offline: mvn -o -Dexec.args='$EXT' '$LOG4J' '$HAWTIO' exec:java 2>&1" >signalk-static/logs/start.log 2>&1 
mvn -o -Dexec.args="'$EXT' '$LOG4J' '$HAWTIO' '$JOLOKIA'" exec:exec >>signalk-static/logs/start.log 2>&1
