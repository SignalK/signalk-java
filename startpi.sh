#!/bin/bash
#
# start script for freeboard on a Raspberry Pi
#
#SIGNALK_HOME=/home/pi/signalk-server
SIGNALK_HOME=`pwd`

#
cd $SIGNALK_HOME
mkdir -p signalk-static/logs

#temporary until linux-arm.jar is in purejavacom.jar
export LD_LIBRARY_PATH=$SIGNALK_HOME/jna

EXT="-Djava.util.Arrays.useLegacyMergeSort=true"
MEM="-Xmx32m -XX:PermSize=32m -XX:MaxPermSize=48m"
HAWTIO=-Dhawtio.authenticationEnabled=false
LOG4J=-Dlog4j.configuration=file://$SIGNALK_HOME/conf/log4j2.json

cd $SIGNALK_HOME
#mvn $EXT $LOG4J exec:java 2>&1 &" >>signalk-static/logs/start.log 2>&1 &
#mvn $EXT $LOG4J exec:java 
#>>logs/start.log 2>&1 &
echo "Starting offline: mvn -Dexec.args='$EXT' '$LOG4J' '$HAWTIO' exec:java 2>&1 &" >>signalk-static/logs/start.log 2>&1 &
mvn -Dexec.args="'$EXT' '$LOG4J' '$HAWTIO'" exec:java >>signalk-static/logs/start.log 2>&1 &
