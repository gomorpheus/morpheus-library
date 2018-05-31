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

configure(){

  cp /tmp/morpheus-welcome-all.jar /app.jar
  chmod 777 /app.jar

  case "$OS_RELEASE" in
   ubuntu)

    case "$OS_VERSION" in
      16.04)
        if [ -f /tmp/java.service ]; then
          echo "Moving Java systemd file into place..."
          mv /tmp/java.service /etc/systemd/system/java.service
          chown root.root /etc/systemd/system/java.service
          chmod 644 /etc/systemd/system/java.service
        else
          echo "Java systemd file not found at /tmp/java.service"
          exit 1
        fi
      ;;
      *)
        if [ -f /tmp/java.override ]; then
          echo "Moving Java service override into place..."
          mv /tmp/java.override /etc/init/
          chown root.root /etc/init/java.override
          chmod 644 /etc/init/java.override
        else
          echo "Java service override file not found at /tmp/java.override"
          exit 1
        fi

        if [ -f /tmp/java.conf ]; then
          echo "Moving Java service job file into place..."
          mv /tmp/java.conf /etc/init/
          chown root.root /etc/init/java.conf
          chmod 644 /etc/init/java.conf
        else
          echo "Java service job file not found at /tmp/java.conf"
          exit 1
        fi
      ;;
    esac
   ;;

   centos|rhel|ol)
    if [ -f /tmp/java.service ]; then
      echo "Moving Java systemd file into place..."
      mv /tmp/java.service /etc/systemd/system/java.service
      chown root.root /etc/systemd/system/java.service
      chmod 644 /etc/systemd/system/java.service
    else
      echo "Java systemd file not found at /tmp/java.service"
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
configure
stat

