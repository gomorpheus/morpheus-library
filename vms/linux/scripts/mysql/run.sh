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

installMysql(){
  groupadd --system mysql
  useradd mysql -d /var/lib/mysql -s /bin/false --system --no-create-home -g mysql

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

  ln -s /morpheus/config /etc/mysql
  chmod 755 /etc/mysql
#  chown mysql:mysql /etc/mysql

  mkdir -p /morpheus/logs/mysql
  ln -s /morpheus/logs/mysql /var/log/mysql
  chmod 755 /var/log/mysql
  chown mysql:mysql /var/log/mysql

  touch /var/log/mysql/mysql.log
  chmod 644 /var/log/mysql/mysql.log
  chown mysql:mysql /var/log/mysql/mysql.log

  touch /var/log/mysql/slow.log
  chmod 644 /var/log/mysql/slow.log
  chown mysql:mysql /var/log/mysql/slow.log

  touch /var/log/mysql/error.log
  chmod 644 /var/log/mysql/error.log
  chown mysql:mysql /var/log/mysql/error.log

  if [ -z "$MYSQL_VERSION" ]; then
    echo "No MYSQL_VERSION was set in environment, this should be set in Packer."
    exit 1
  else
    case "$OS_RELEASE" in
     ubuntu)
      chmod 0755 /tmp/mysql-gpg-key.asc
      echo "Adding MySQL GPG key"
      apt-key add /tmp/mysql-gpg-key.asc
      apt-get update
      echo "deb http://repo.mysql.com/apt/ubuntu trusty $MYSQL_VERSION" > /etc/apt/sources.list.d/mysql.list

      export DEBIAN_FRONTEND=noninteractive

      debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
      debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ''"
      debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ''"
      debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-test-db select false"

      apt-get update
      apt-get install -y mysql-server
      service mysql stop
      rm -rf /var/lib/mysql
      mkdir -p /var/lib/mysql
      chmod 755 /var/lib/mysql
      chown mysql:mysql /var/lib/mysql
      sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
      update-rc.d -f mysql remove
     ;;

     centos|rhel|ol)
      yum install haveged -y
      ;;
     
     *)
      ;;
    esac  
  fi

  if [ "$MYSQL_VERSION" == "mysql-5.6" ]; then
      sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
  elif [[ "$MYSQL_VERSION" == "mysql-5.7" ]]; then
      sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/mysql.conf.d/mysqld.cnf
  fi

}

configure(){

  if [ -f /tmp/my.cnf ]; then
    echo "Moving MySQL config file into place..."
    mv /tmp/my.cnf /etc/mysql/
    chown mysql.mysql /etc/mysql/my.cnf
    chmod 644 /etc/mysql/my.cnf
  else
    echo "MySQL config file not found at /tmp/my.cnf"
  fi

  chown -R mysql:mysql /morpheus/config/

  if [ -f /tmp/mysql.init ]; then
    echo "Moving MySQL init file into place..."
    mv /tmp/mysql.init /etc/init.d/mysql
#    chown mysql.mysql /etc/mysql/my.cnf
    chmod 755 /etc/init.d/mysql
  else
    echo "MySQL init file not found at /tmp/mysql.init"
  fi

  case "$OS_RELEASE" in
   ubuntu)
    case "$OS_VERSION" in
      16.04)
      ;;
      *)
      ;;
    esac
   ;;

   centos|rhel|ol)
    ;;
   
   *)
    ;;
   esac

  if [ -f /tmp/morpheus-entrypoint.sh ]; then
    echo "Moving morpheus entrypoint file into place..."
    mv /tmp/morpheus-entrypoint.sh /entrypoint.sh
    chown root.root /entrypoint.sh
    chmod 777 /entrypoint.sh
  else
    echo "Morpheus entrypoint file not found at /tmp/morpheus-entrypoint.sh"
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
installMysql
stat
configure
stat

