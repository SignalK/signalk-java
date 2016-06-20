#!/bin/bash
#
# start script for freeboard on a Raspberry Pi
#
#SIGNALK_HOME=/home/pi/signalk-server
SIGNALK_HOME=`pwd`

#
cd $SIGNALK_HOME
mkdir logs

#temporary until linux-arm.jar is in purejavacom.jar
export LD_LIBRARY_PATH=$SIGNALK_HOME/jna

EXT="-Djava.util.Arrays.useLegacyMergeSort=true"
MEM="-Xmx32m -XX:PermSize=32m -XX:MaxPermSize=48m"

LOG4J=-Dlog4j.configuration=file://$SIGNALK_HOME/conf/log4j2.json

cd $SIGNALK_HOME
mvn $EXT $LOG4J exec:java 2>&1 &" >>logs/start.log 2>&1 &
mvn $EXT $LOG4J exec:java 
#>>logs/start.log 2>&1 &
