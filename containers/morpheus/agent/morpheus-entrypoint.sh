#!/bin/bash
set -e

JAVA_STARTUP="-jar agent.jar"

if [ "$1" = 'java' ]; then
	# if second arg is base 64 encoded config
	if [ -z "$AGENT_CONFIG" ]; then
		if [ "$2" ]; then
    		JAVA_STARTUP="$JAVA_STARTUP -j $2"
    		echo $JAVA_STARTUP
		fi
	else
		JAVA_STARTUP="$JAVA_STARTUP $AGENT_CONFIG"
	fi
	#show what were doing
	echo "agent startup: $JAVA_STARTUP"
	#run the jar
	java -Xms$JVM_MIN_MEM -Xmx$JVM_MAX_MEM $JAVA_STARTUP 
fi

exec "$@"
