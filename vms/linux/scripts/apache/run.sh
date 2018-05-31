#!/bin/bash -eu
. /tmp/os_detect.sh

installDependencies(){
  echo "create staging directory"
  mkdir -p /staging

  PACKAGES="haveged"
  echo "Installing $PACKAGES"
  case "$OS_RELEASE" in
   ubuntu)
     apt-get -y install $PACKAGES

    if [ ! -d "/morpheus/config/apache2" ]; then
      echo "/morpheus/config/apache2 doesn't exist so create it"
      mkdir -p /morpheus/config/apache2
    fi

    if [ ! -d "/etc/apache2" ]; then
      echo "/etc/apache2 doesn't exist so create it"
      ln -s /morpheus/config /etc/apache2
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

    if [ ! -d "/morpheus/logs/apache2" ]; then
      echo "/morpheus/logs/apache2 doesn't exist so create it"
      mkdir -p /morpheus/logs/apache2
    fi

    if [ ! -d "/var/log/apache2" ]; then
      echo "/var/log/apache2 doesn't exist so create it"
      ln -s /morpheus/logs/apache2 /var/log/apache2
    fi

    if [ ! -d "/var/lock" ]; then
      echo "/var/lock doesn't exist so create it"
      mkdir -p /var/lock
    fi

    if [ ! -d "/var/lock/apache2" ]; then
      echo "/var/lock/apache2 doesn't exist so create it"
      mkdir -p /var/lock/apache2
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

installApache(){
  
  echo "Installing $PACKAGES"
  case "$OS_RELEASE" in
   ubuntu)
    PACKAGES="apache2"
    apt-get -y install $PACKAGES
   ;;

   centos|rhel|ol)
    PACKAGES="httpd mod_ssl openssl"
    yum -y install $PACKAGES
    echo "copy default html files"
    cp -Rf /usr/share/httpd/noindex/* /var/www/html/
    ;;
   
   *)
    ;;
   esac  
}

configure(){
  case "$OS_RELEASE" in
   ubuntu)
    cp /morpheus/config/envvars /morpheus/config/envvars.orig
    sed -i "/export APACHE_PID_FILE/c\export APACHE_PID_FILE=/var/run/apache2$SUFFIX.pid" /morpheus/config/envvars
    sed -i "/export APACHE_RUN_DIR/c\export APACHE_RUN_DIR=/etc/apache2" /morpheus/config/envvars
    sed -i "/export APACHE_RUN_USER/c\export APACHE_RUN_USER=www-data" /morpheus/config/envvars
    sed -i "/export APACHE_RUN_GROUP/c\export APACHE_RUN_GROUP=www-data" /morpheus/config/envvars
    sed -i "/export APACHE_LOG_DIR/c\export APACHE_LOG_DIR=/var/log/apache2" /morpheus/config/envvars
    sed -i "/export APACHE_LOCK_DIR/c\export APACHE_LOCK_DIR=/var/lock/apache2" /morpheus/config/envvars

    if [ -f /tmp/apache2.conf ]; then
      echo "Moving Apache config file into place..."
      mv /tmp/apache2.conf /etc/apache2/apache2.conf
      chmod 644 /etc/apache2/apache2.conf
    else
      echo "Apache config file not found at /tmp/apache2.conf"
      exit 1
    fi

    if [ ! -f /etc/apache2/sites-enabled/001-default-ssl.conf ]; then
      echo "Enabling default ssl site..."
      ln -sf /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/001-default-ssl.conf
    fi

    if [ ! -f /etc/apache2/mods-enabled/ssl.conf ]; then
      echo "Enabling ssl config file..."
      ln -sf /etc/apache2/mods-available/ssl.conf /etc/apache2/mods-enabled/
    fi

    if [ ! -f /etc/apache2/mods-enabled/ssl.load ]; then
      echo "Enabling ssl load file..."
      ln -sf /etc/apache2/mods-available/ssl.load /etc/apache2/mods-enabled/
    fi

    if [ ! -f /etc/apache2/mods-enabled/socache_shmcb.load ]; then
      echo "Copying socache_shmcb.load file..."
      ln -sf /etc/apache2/mods-available/socache_shmcb.load /etc/apache2/mods-enabled/
    fi

    cp -r /etc/ssl /staging/
   ;;

   centos|rhel|ol)
    if [ -f /tmp/httpd.conf ]; then
      echo "Moving Apache config file into place..."
      mv /tmp/httpd.conf /etc/httpd/conf/httpd.conf
      chmod 644 /etc/httpd/conf/httpd.conf
    else
      echo "Apache config file not found at /tmp/httpd.conf"
      exit 1
    fi
    if [ -f /tmp/ssl.conf ]; then
      echo "Moving Apache SSL config file into place..."
      mv /tmp/ssl.conf /etc/httpd/conf/ssl.conf
      chmod 644 /etc/httpd/conf/ssl.conf
    else
      echo "Apache SSL config file not found at /tmp/ssl.conf"
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
installApache
stat
configure
stat

