#!/bin/bash
set -e

if [ -e "/var/opt/morpheus/vm/morpheus.env" ]; then
	source /var/opt/morpheus/vm/morpheus.env
fi
# This varies per underlying base OS so it has to be set there
#export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export CATALINA_HOME=/usr/local/tomcat
export CONFIG_HOME=/morpheus/config
export APP_HOME=/morpheus/data
export LOGS_HOME=/morpheus/logs
export STAGING_HOME=$APP_HOME/staging
export CATALINA_BASE=$APP_HOME/tomcat
export JAVA_OPTS="-Djava.awt.headless=true"

sudo chown -R morpheus-node.morpheus-node $CATALINA_HOME

if [[ ! -d $CATALINA_BASE ]]; then
	echo "$CATALINA_BASE does not exist so create it"
	mkdir -p $CATALINA_BASE
	mkdir -p $CATALINA_BASE/webapps
fi

if [[ ! -d $CATALINA_BASE/temp ]]; then
	echo "$CATALINA_BASE/temp does not exist so create it"
	mkdir -p $CATALINA_BASE/temp
fi

if [[ ! -d $CATALINA_BASE/work ]]; then
	echo "$CATALINA_BASE/work does not exist so create it"
	mkdir -p $CATALINA_BASE/work
fi

if [[ ! -d $STAGING_HOME ]]; then
	echo "$STAGING_HOME does not exist so create it"
	mkdir -p $STAGING_HOME
fi

if [ ! -d "/morpheus/data/tomcat/conf" ]; then
  echo "/morpheus/data/tomcat/conf doesn't exist so create it"
  ln -s /morpheus/config /morpheus/data/tomcat/conf
fi

if [ ! -d "/morpheus/data/tomcat/lib" ]; then
  echo "/morpheus/data/tomcat/lib doesn't exist so create it"
  mkdir /morpheus/data/tomcat/lib
  cp -r /usr/local/tomcat/lib/* /morpheus/data/tomcat/lib/
fi

if [ ! -d "/morpheus/data/tomcat/logs" ]; then
  echo "/morpheus/data/tomcat/logs doesn't exist so create it"
  ln -s /morpheus/logs /morpheus/data/tomcat/logs
fi

sudo chown -R morpheus-node.morpheus-node $CATALINA_BASE
sudo chown -R morpheus-node.morpheus-node $STAGING_HOME

if [[ -e $STAGING_HOME/ROOT.war ]]; then
	echo "removing files from webapps directory"
	rm -rf $CATALINA_BASE/webapps/ROOT*
	echo "copying new war to webapps"
	cp $STAGING_HOME/ROOT.war $CATALINA_BASE/webapps/
fi

if [[ ! -e $CONFIG_HOME/startup.txt ]]; then
	cp /startup.txt $CONFIG_HOME/
fi

export CATALINA_OPTS=`cat /morpheus/config/startup.txt`
cd $CATALINA_BASE
exec /usr/local/tomcat/bin/catalina.sh run
