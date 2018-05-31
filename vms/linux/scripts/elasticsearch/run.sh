#!/bin/bash -eu
. /tmp/os_detect.sh

installDependencies(){
  PACKAGES="haveged"
  echo "Installing $PACKAGES"
  case "$OS_RELEASE" in
   ubuntu)
     apt-get -y install $PACKAGES

    groupadd --system elasticsearch
    useradd elasticsearch -d /home/elasticsearch -s /bin/false --system --no-create-home -g elasticsearch

    if [ ! -d "/morpheus/config" ]; then
      echo "/morpheus/config doesn't exist so create it"
      mkdir -p /morpheus/config
    fi

    if [ ! -d "/etc/elasticsearch" ]; then
      echo "/etc/elasticsearch doesn't exist so create it"
      ln -s /morpheus/config /etc/elasticsearch
      chown elasticsearch:elasticsearch /etc/elasticsearch
    fi

    if [ ! -d "/morpheus/data" ]; then
      echo "/morpheus/data doesn't exist so create it"
      mkdir -p /morpheus/data
    fi

    if [ ! -d "/var/lib" ]; then
      echo "/var/lib doesn't exist so create it"
      mkdir -p /var/lib
    fi

    if [ ! -d "/var/lib/elasticsearch" ]; then
      echo "/var/lib/elasticsearch doesn't exist so create it"
      ln -s /morpheus/data /var/lib/elasticsearch
      chown elasticsearch:elasticsearch /var/lib/elasticsearch
    fi

    if [ ! -d "/morpheus/logs/elasticsearch" ]; then
      echo "/morpheus/logs/elasticsearch doesn't exist so create it"
      mkdir -p /morpheus/logs/elasticsearch
    fi

    if [ ! -d "/var/log/elasticsearch" ]; then
      echo "/var/log/elasticsearch doesn't exist so create it"
      ln -s /morpheus/logs/elasticsearch /var/log/elasticsearch
      chown elasticsearch:elasticsearch /var/log/elasticsearch
    fi
   ;;

   centos|rhel|ol)
    yum -y install $PACKAGES

    if [ ! -d "/morpheus/config/httpd" ]; then
      echo "/morpheus/config/httpd doesn't exist so create it"
      mkdir -p /morpheus/config/httpd
    fi

    if [ ! -d "/etc/httpd" ]; then
      echo "/etc/httpd doesn't exist so create it"
      ln -s /morpheus/config /etc/httpd
    fi

    if [ ! -d "/morpheus/data" ]; then
      echo "/morpheus/data doesn't exist so create it"
      mkdir -p /morpheus/data
    fi

    if [ ! -d "/var/www" ]; then
      echo "/var/www doesn't exist so create it"
      mkdir -p /var/www
    fi

    if [ ! -d "/var/www/html" ]; then
      echo "/var/www/html doesn't exist so create it"
      ln -s /morpheus/data /var/www/html
    fi

    if [ ! -d "/morpheus/logs/httpd" ]; then
      echo "/morpheus/logs/httpd doesn't exist so create it"
      mkdir -p /morpheus/logs/httpd
    fi

    if [ ! -d "/var/log/httpd" ]; then
      echo "/var/log/httpd doesn't exist so create it"
      ln -s /morpheus/logs/httpd /var/log/httpd
    fi
    ;;
   
   *)
    ;;
   esac  
}

installSoftware(){
  case "$OS_RELEASE" in
   ubuntu)
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
        dpkg -i "/tmp/$PACKAGE_NAME"
      else
        echo "Downloaded file does not match expected checksum, expected $DOWNLOAD_CHECKSUM and got $CHECKSUM using type $DOWNLOAD_CHECKSUM_TYPE"
        exit 1
      fi
    fi

    if [ -f /tmp/elasticsearch.override ]; then
      echo "Moving Elasticsearch service override into place..."
      mv /tmp/elasticsearch.override /etc/init/
      chown root.root /etc/init/elasticsearch.override
      chmod 644 /etc/init/elasticsearch.override
    else
      echo "Elasticsearch service override file not found at /tmp/elasticsearch.override"
      exit 1
    fi

    if [ -f /tmp/entrypoint.sh ]; then
      echo "Moving entrypoint service start script into place..."
      mv /tmp/entrypoint.sh /
      chown root.root /entrypoint.sh
      chmod 755 /entrypoint.sh
    else
      echo "Entrypoint service start script not found at /tmp/entrypoint.sh"
      exit 1
    fi

    if [ -f /tmp/elasticsearch.conf ]; then
      echo "Moving Elasticsearch service job into place..."
      mv /tmp/elasticsearch.conf /etc/init.d/elasticsearch
      chown root.root /etc/init.d/elasticsearch
      chmod 755 /etc/init.d/elasticsearch
    else
      echo "Elasticsearch service job file not found at /tmp/elasticsearch.conf"
      exit 1
    fi

#    if [ -f /tmp/elasticsearch.conf ]; then
#      echo "Moving ElasticSearch service job into place..."
#      mv /tmp/elasticsearch.conf /etc/init/
#      chown root.root /etc/init/elasticsearch.conf
#      chmod 644 /etc/init/elasticsearch.conf
#    else
#      echo "ElasticSearch service job file not found at /tmp/elasticsearch.conf"
#      exit 1
#    fi
   ;;

   centos|rhel|ol)
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
installSoftware
stat