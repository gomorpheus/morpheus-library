#!/bin/bash
. /tmp/os_detect.sh

installDependencies(){
  case "$OS_RELEASE" in
   ubuntu)
   apt-get install haveged -y
   ;;

   centos|rhel|ol)
    yum install haveged -y
    ;;
   
   *)
    ;;
   esac  
}

installJdk(){
  case "$OS_RELEASE" in
   ubuntu)
   add-apt-repository ppa:openjdk-r/ppa -y
   apt-get update -y
   apt-get install build-essential openjdk-8-jdk -y
   update-alternatives --config java
   update-alternatives --config javac
   ;;

   centos|rhel|ol)
    yum install java-1.8.0-openjdk -y
    ;;
   
   *)
    ;;
   esac  
}

installTomcat(){
  cd /opt
  if [ -z "$DOWNLOAD_URL" ]; then
    echo "No DOWNLOAD_URL was set in environment, this should be set in Packer."
    exit 1
  else
    PACKAGE_NAME=${DOWNLOAD_URL##*/}
    echo "Downloading $PACKAGE_NAME from $DOWNLOAD_URL"
    wget -q -O "/tmp/$PACKAGE_NAME" "$DOWNLOAD_URL"
  fi

  if [ ! -d "/morpheus/config" ]; then
    echo "/morpheus/config doesn't exist so create it"
    mkdir -p /morpheus/config
  fi

  if [ ! -d "/morpheus/data" ]; then
    echo "/morpheus/data doesn't exist so create it"
    mkdir -p /morpheus/data
  fi

  if [ ! -d "/morpheus/logs" ]; then
    echo "/morpheus/logs doesn't exist so create it"
    mkdir -p /morpheus/logs
  fi

  if [ ! -d "/morpheus/data/staging" ]; then
    echo "/morpheus/data/staging doesn't exist so create it"
    mkdir -p /morpheus/data/staging
  fi

  if [ -f "/tmp/$PACKAGE_NAME" ]; then
    CHECKSUM=$(openssl dgst -"$DOWNLOAD_CHECKSUM_TYPE" "/tmp/$PACKAGE_NAME" | cut -d ' ' -f 2)
    if [ $CHECKSUM == $DOWNLOAD_CHECKSUM ]; then
      mkdir -p /usr/local/tomcat
      tar -xzf "/tmp/$PACKAGE_NAME" -C /usr/local/tomcat --strip-components=1
    else
      echo "Downloaded file does not match expected checksum, expected $DOWNLOAD_CHECKSUM and got $CHECKSUM using type $DOWNLOAD_CHECKSUM_TYPE"
      exit 1
    fi
  fi

  if [ ! -d "/morpheus/data/tomcat" ]; then
    echo "/morpheus/data/tomcat doesn't exist so create it"
    mkdir -p /morpheus/data/tomcat
  fi

  mkdir /morpheus/data/tomcat/bin
  cp /usr/local/tomcat/bin/*.sh /morpheus/data/tomcat/bin/
  cp /usr/local/tomcat/bin/*.bat /morpheus/data/tomcat/bin/
  cp /usr/local/tomcat/bin/tomcat-juli.jar /morpheus/data/tomcat/bin/

  ln -s /morpheus/config /morpheus/data/tomcat/conf
  cp -r /usr/local/tomcat/conf/* /morpheus/config

  mkdir /morpheus/data/tomcat/lib
  cp -r /usr/local/tomcat/lib/* /morpheus/data/tomcat/lib/

  ln -s /morpheus/logs /morpheus/data/tomcat/logs

  mkdir /morpheus/data/tomcat/webapps
  cp -r /usr/local/tomcat/webapps/* /morpheus/data/tomcat/webapps/

  mkdir /morpheus/data/tomcat/work

  mkdir /morpheus/data/tomcat/temp
}

configure(){
#  groupadd tomcat
#  useradd  -g tomcat -d /usr/local/tomcat tomcat
#  chown -hR tomcat:tomcat /usr/local/tomcat
#  chmod +x /usr/local/tomcat/bin/*
#  echo 'export CATALINA_HOME=/usr/local/tomcat' | tee -a /etc/profile

  case "$OS_RELEASE" in
   ubuntu)

    case "$OS_VERSION" in
      16.04)
        if [ -f /tmp/tomcat.service ]; then
          echo "Moving Tomcat systemd file into place..."
          mv /tmp/tomcat.service /etc/systemd/system/tomcat.service
          chown root.root /etc/systemd/system/tomcat.service
          chmod 644 /etc/systemd/system/tomcat.service
        else
          echo "Tomcat systemd file not found at /tmp/tomcat.service"
          exit 1
        fi
      ;;
      *)
        if [ -f /tmp/tomcat.override ]; then
          echo "Moving Tomcat service override into place..."
          mv /tmp/tomcat.override /etc/init/
          chown root.root /etc/init/tomcat.override
          chmod 644 /etc/init/tomcat.override
        else
          echo "Tomcat service override file not found at /tmp/tomcat.override"
          exit 1
        fi

        if [ -f /tmp/tomcat.conf ]; then
          echo "Moving Tomcat service job file into place..."
          mv /tmp/tomcat.conf /etc/init/
          chown root.root /etc/init/tomcat.conf
          chmod 644 /etc/init/tomcat.conf
        else
          echo "Tomcat service job file not found at /tmp/tomcat.conf"
          exit 1
        fi
      ;;
    esac
   ;;

   centos|rhel|ol)
    if [ -f /tmp/tomcat.service ]; then
      echo "Moving Tomcat systemd file into place..."
      mv /tmp/tomcat.service /etc/systemd/system/tomcat.service
      chown root.root /etc/systemd/system/tomcat.service
      chmod 644 /etc/systemd/system/tomcat.service
    else
      echo "Tomcat systemd file not found at /tmp/tomcat.service"
      exit 1
    fi
    ;;
   
   *)
    ;;
   esac

  if [ -f /tmp/entrypoint.sh ]; then
    echo "Moving entrypoint service start script into place..."
    mv /tmp/entrypoint.sh /
    chown root.root /entrypoint.sh
    chmod 755 /entrypoint.sh
  else
    echo "Entrypoint service start script not found at /tmp/entrypoint.sh"
    exit 1
  fi

  if [ -f /tmp/startup.txt ]; then
    echo "Moving startup file into place..."
    mv /tmp/startup.txt /
    chown root.root /startup.txt
    chmod 755 /startup.txt
  else
    echo "Startup file not found at /tmp/startup.txt"
    exit 1
  fi
}


stat(){
  if [ $? != 0 ]
  then
        echo "failed in installation"
        exit 2
  fi
}

installDependencies
stat
installTomcat
stat
configure
stat

