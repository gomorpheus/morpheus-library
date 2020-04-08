#!/bin/bash -e
. /tmp/os_detect.sh

if [ -z $RUN_AS ]; then
  RUN_AS=root
fi

installDependencies(){

  PACKAGES="ntp"
  case "$OS_RELEASE" in
   ubuntu)
    echo "Detected Ubuntu OS"
    apt-get -y update
   apt-get -y install $PACKAGES
   ;;

   centos|rhel|ol)
    echo "Detected CentOS or RedHat or Oracle OS"
    yum -y install $PACKAGES
    ;;
   
   *)
    echo "Unsupported OS $OS_RELEASE"
    ;;
   esac  
}

moveNtpConfigurationFiles(){
  case "$OS_RELEASE" in
   ubuntu)
    echo "Detected Ubuntu OS"
    if [ -f /tmp/ntp.conf ]; then
      echo "Moving NTP configuration file into place..."
      mv /etc/ntp.conf /etc/ntp.conf.orig
      mv /tmp/ntp.conf /etc/
      chown root.root /etc/ntp.conf
      chmod 644 /etc/ntp.conf
    else
      echo "NTP configuration file not found at /tmp/ntp.conf"
      exit 1
    fi

    if [ -f /tmp/ntp.leapseconds ]; then
      echo "Moving NTP leap seconds configuration file into place..."
      mv /tmp/ntp.leapseconds /etc/
      chown root.root /etc/ntp.leapseconds
      chmod 644 /etc/ntp.leapseconds
    else
      echo "NTP leap seconds configuration file not found at /tmp/ntp.leapseconds"
      exit 1
    fi
    service ntp restart
   ;;

   centos|rhel|ol)
    echo "Detected CentOS or RedHat or Oracle OS"
    if [ -f /tmp/ntp.conf ]; then
      echo "Moving NTP configuration file into place..."
      mv /etc/ntp.conf /etc/ntp.conf.orig
      mv /tmp/ntp.conf /etc/
      chown root.root /etc/ntp.conf
      chmod 644 /etc/ntp.conf
    else
      echo "NTP configuration file not found at /tmp/ntp.conf"
      exit 1
    fi

    if [ -f /tmp/ntp.leapseconds ]; then
      echo "Moving NTP leap seconds configuration file into place..."
      mv /tmp/ntp.leapseconds /etc/
      chown root.root /etc/ntp.leapseconds
      chmod 644 /etc/ntp.leapseconds
    else
      echo "NTP leap seconds configuration file not found at /tmp/ntp.leapseconds"
      exit 1
    fi
    service ntpd restart   
    ;;

   *)
    ;;
   esac  
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
moveNtpConfigurationFiles
stat
