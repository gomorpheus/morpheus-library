#!/bin/bash
. /tmp/os_detect.sh

installDependencies(){
  case "$OS_RELEASE" in
   ubuntu)
   apt-get -y install perl libssl1.0.0 libpcre3 gcc libc6-dev libpcre3-dev libssl-dev make
   ;;

   centos|rhel|ol)
    yum -y update openssl
    yum -y install pcre-devel openssl-devel
    yum -y install perl gcc make
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

InstallHaProxy(){

  if [ -z "$DOWNLOAD_URL" ]; then
    echo "No DOWNLOAD_URL was set in environment, this should be set in Packer."
    exit 1
  else
    PACKAGE_NAME=${DOWNLOAD_URL##*/}
    echo "Downloading $PACKAGE_NAME from $DOWNLOAD_URL"
    wget -q -O "/tmp/$PACKAGE_NAME" "$DOWNLOAD_URL"
  fi

  if [ -f "/tmp/$PACKAGE_NAME" ]; then
    CHECKSUM=$(openssl dgst -"$DOWNLOAD_CHECKSUM_TYPE" "/tmp/$PACKAGE_NAME" | cut -d ' ' -f 2)
    if [ $CHECKSUM == $DOWNLOAD_CHECKSUM ]; then
      mkdir -p /usr/src/haproxy
      tar -xzf "/tmp/$PACKAGE_NAME" -C /usr/src/haproxy --strip-components=1

      #build haproxy
      make -C /usr/src/haproxy TARGET=linux2628 USE_PCRE=1 PCREDIR= USE_OPENSSL=1 USE_ZLIB=1 all install-bin
      mkdir -p /usr/local/etc/haproxy
      cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors
      rm -rf /usr/src/haproxy

    else
      echo "Downloaded file does not match expected checksum, expected $DOWNLOAD_CHECKSUM and got $CHECKSUM using type $DOWNLOAD_CHECKSUM_TYPE"
      exit 1
    fi
  fi

  case "$OS_RELEASE" in
   ubuntu)
    ;;

   centos|rhel|ol)
    ;;
   
   *)
    ;;
   esac

}

configure(){
  case "$OS_RELEASE" in
   ubuntu)
    if [ -f /tmp/haproxy.override ]; then
      echo "Moving HAProxy service override into place..."
      mv /tmp/haproxy.override /etc/init/
      chown root.root /etc/init/haproxy.override
      chmod 644 /etc/init/haproxy.override
    else
      echo "HAProxy service override file not found at /tmp/haproxy.override"
      exit 1
    fi

    if [ -f /tmp/haproxy.conf ]; then
      echo "Moving HAProxy service job file into place..."
      mv /tmp/haproxy.conf /etc/init/
      chown root.root /etc/init/haproxy.conf
      chmod 644 /etc/init/haproxy.conf
    else
      echo "HAProxy service job file not found at /tmp/haproxy.conf"
      exit 1
    fi

   ;;

   centos|rhel|ol)
    if [ -f /tmp/haproxy.conf ]; then
      echo "Moving HAProxy service job file into place..."
      mv /tmp/haproxy.conf /etc/init.d/haproxy
      chown root.root /etc/init.d/haproxy
      chmod 644 /etc/init.d/haproxy
    else
      echo "HAProxy service job file not found at /tmp/haproxy.conf"
      exit 1
    fi

    ;;
   
   *)
    ;;
   esac

  if [ -f /tmp/haproxy.cfg ]; then
    echo "Moving HAProxy configuration into place..."
    mv /tmp/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
    chown root.root /usr/local/etc/haproxy/haproxy.cfg
    chmod 777 /usr/local/etc/haproxy/haproxy.cfg
  else
    echo "HAProxy configuration file not found at /tmp/haproxy.cfg"
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
InstallHaProxy
stat
configure
stat

