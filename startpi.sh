#!/bin/bash
#
# start script for freeboard on a Raspberry Pi
#
#SIGNALK_HOME=/home/pi/signalk-server
SIGNALK_HOME=`pwd`

JAR=signalk-server-0.0.1-SNAPSHOT-jar-with-dependencies.jar
#
cd $SIGNALK_HOME
mkdir logs

#temporary until linux-arm.jar is in purejavacom.jar
export LD_LIBRARY_PATH=$SIGNALK_HOME/jna

EXT="-Djava.util.Arrays.useLegacyMergeSort=true"
MEM="-Xmx32m -XX:PermSize=32m -XX:MaxPermSize=48m"

LOG4J=-Dlog4j.configuration=file://$SIGNALK_HOME/conf/log4j.properties

cd $SIGNALK_HOME
echo "Starting: $JAVA $EXT $LOG4J $MEM -jar target/$JAR >>logs/start.log 2>&1 &" >>logs/start.log 2>&1 &
$JAVA $EXT $LOG4J $MEM -jar target/$JAR 
#>>logs/start.log 2>&1 &
