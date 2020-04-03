#!/bin/bash
set -e

CONFIG_HOME=/morpheus/config
APP_HOME=/morpheus/data
LOGS_HOME=/morpheus/logs

files=$(ls $APP_HOME/*.jar 2> /dev/null | wc -l)
if [ "$files" = "0" ]; then
   cp /app.jar $APP_HOME/
fi

cd /morpheus/data

JAVA_STARTUP="-Dratpack.port=8080 -jar app.jar"

if [[ -e $CONFIG_HOME/startup.txt ]]; then
	JAVA_STARTUP=`cat /morpheus/config/startup.txt`
fi

if [ "$1" = 'java' ]; then
	java -Xms$JVM_MIN_MEM -Xmx$JVM_MAX_MEM  $JAVA_STARTUP > $LOGS_HOME/app.log
fi

exec "$@"
