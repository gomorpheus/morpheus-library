#!/bin/bash -eu
. /tmp/os_detect.sh

if [ -z $RUN_AS ]; then
  RUN_AS=root
fi

installDependencies(){

  PACKAGES="gcc make"
  case "$OS_RELEASE" in
   ubuntu)
   apt-get -y install $PACKAGES
   ;;

   centos|rhel|ol)
    yum -y install $PACKAGES
    ;;
   
   *)
    ;;
   esac  
}

InstallRedis(){

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

      groupadd --system redis
      useradd redis -d /var/lib/redis -s /bin/false --system --no-create-home -g redis

      mkdir -p /morpheus/config
      ln -s /morpheus/config /etc/redis
      chmod 755 /etc/redis
      chown redis:redis /etc/redis

      mkdir -p /morpheus/data/redis
      ln -s /morpheus/data/redis /var/redis
      chmod 755 /var/redis
      chown redis:redis /var/redis

      mkdir -p /morpheus/logs/redis
      ln -s /morpheus/logs/redis /var/log/redis
      chmod 755 /var/log/redis

      touch /var/log/redis/redis-server.log
      chmod 777 /var/log/redis/redis-server.log
      chown redis:redis /var/log/redis/redis-server.log

      mkdir -p /usr/src/redis
      tar -xzf "/tmp/$PACKAGE_NAME" -C /usr/src/redis --strip-components=1

      #build redis
      make -C /usr/src/redis TARGET=linux2628 USE_ZLIB=1 all install

    else
      echo "Downloaded file does not match expected checksum, expected $DOWNLOAD_CHECKSUM and got $CHECKSUM using type $DOWNLOAD_CHECKSUM_TYPE"
      exit 1
    fi
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
}

configure(){
  case "$OS_RELEASE" in
   ubuntu)
    if [ -f /tmp/redis-server.override ]; then
      echo "Moving Redis Server service override into place..."
      mv /tmp/redis-server.override /etc/init/
      chown root.root /etc/init/redis-server.override
      chmod 644 /etc/init/redis-server.override
    else
      echo "Redis Server service override file not found at /tmp/redis-server.override"
      exit 1
    fi

    if [ -f /tmp/redis-server.conf ]; then
      echo "Moving Redis Server service job file into place..."
      mv /tmp/redis-server.conf /etc/init/
      chown root.root /etc/init/redis-server.conf
      chmod 644 /etc/init/redis-server.conf
    else
      echo "Redis Server service job file not found at /tmp/redis-server.conf"
      exit 1
    fi

   ;;

   centos|rhel|ol)
    if [ -f /tmp/redis-server.conf ]; then
      echo "Moving Redis Server service job file into place..."
      mv /tmp/redis-server.conf /etc/init.d
      chown root.root /etc/init.d/redis-server.conf
      chmod 644 /etc/init.d/redis-server.conf
    else
      echo "Redis Server service job file not found at /tmp/redis-server.conf"
      exit 1
    fi

    ;;
   
   *)
    ;;
   esac

  if [ -f /usr/src/redis/redis.conf ]; then
    echo "Copying Redis Server configuration into place..."
    cp /usr/src/redis/redis.conf /etc/redis/redis.conf
    chown root.root /etc/redis/redis.conf
    chmod 777 /etc/redis/redis.conf
  else
    echo "Redis Server configuration file not found at /usr/src/redis/redis.conf"
    exit 1
  fi

  if [ -f /tmp/create-cluster.sh ]; then
    echo "Moving Create Cluster script into place..."
    mv /tmp/create-cluster.sh /create-cluster.sh
    chown root.root /create-cluster.sh
    chmod 777 /create-cluster.sh
  else
    echo "Create Cluster file not found at /tmp/create-cluster.sh"
    exit 1
  fi

}

InstallRedisClient(){
  sudo su - $RUN_AS -c "source /etc/profile.d/rvm.sh"
  sudo su - $RUN_AS -c "rvm use $RUBY_VERSION"
  echo "Installing ruby redis client as $RUN_AS"
  sudo su - $RUN_AS -c "gem install redis"
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
InstallRedis
stat
InstallRedisClient
stat
configure
stat

