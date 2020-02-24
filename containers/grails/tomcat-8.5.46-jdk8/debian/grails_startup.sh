#!/bin/bash

APP_HOME=/morpheus/data
CATALINA_BASE=$APP_HOME/tomcat
STAGING_HOME=$APP_HOME/staging
CONFIG_HOME=/morpheus/config
LOGS_HOME=/morpheus/logs

export CATALINA_BASE=$APP_HOME/tomcat

if [[ ! -d $CATALINA_BASE ]]; then
	#create the data dir for persistant web apps
	mkdir -p $CATALINA_BASE
	mkdir -p $CATALINA_BASE/webapps
	mkdir -p $CATALINA_BASE/conf
	mkdir -p $CATALINA_BASE/logs
	mkdir -p $STAGING_HOME
	#copy the contents of the home webapps to catalina base
	cp -r $CATALINA_HOME/webapps/ROOT $CATALINA_BASE/webapps/
	cp -r $CATALINA_HOME/webapps/manager $CATALINA_BASE/webapps/
	cp -r $CATALINA_HOME/webapps/host-manager $CATALINA_BASE/webapps/
	cp -r $CATALINA_HOME/conf/* $CATALINA_BASE/conf/
	#make the working directories
	mkdir -p $CATALINA_BASE/temp
	mkdir -p $CATALINA_BASE/work
fi

WAR_LIST=($(ls -d $STAGING_HOME/*.war))
WAR_FILE=${WAR_LIST[0]}

if [[ -e $WAR_FILE ]]; then
	rm -rf $CATALINA_BASE/webapps/ROOT*
	cp $WAR_FILE $CATALINA_BASE/webapps/ROOT.war
fi

if [[ ! -e $CONFIG_HOME/startup.txt ]]; then
	cp /startup.txt $CONFIG_HOME/
fi

CATALINA_OPTS="-Dgrails.env=prod"
export CATALINA_OPTS="$CATALINA_OPTS $(cat /morpheus/config/startup.txt)"

cd $CATALINA_BASE

exec catalina.sh run
