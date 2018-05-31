#!/bin/bash -eu
. /tmp/os_detect.sh

installDependencies(){
  PACKAGES="haveged perl software-properties-common openssh-server zookeeperd rsync libssl-dev libsnappy-dev liblz4-dev libbz2-dev"
  echo "Installing $PACKAGES"
  case "$OS_RELEASE" in
   ubuntu)

    if [ ! -d "/morpheus/config/hadoop" ]; then
      echo "/morpheus/config/hadoop doesn't exist so create it"
      mkdir -p /morpheus/config/hadoop
    fi

    if [ ! -d "/morpheus/data" ]; then
      echo "/morpheus/data doesn't exist so create it"
      mkdir -p /morpheus/data
    fi

    if [ ! -d "/morpheus/logs/hadoop" ]; then
      echo "/morpheus/logs/hadoop doesn't exist so create it"
      mkdir -p /morpheus/logs/hadoop
    fi

    if [ ! -d "/morpheus/logs/zookeeper" ]; then
      echo "/morpheus/logs/zookeeper doesn't exist so create it"
      mkdir -p /morpheus/logs/zookeeper
    fi

    if [ ! -d "/var/log/zookeeper" ]; then
      echo "/var/log/zookeeper doesn't exist so create it"
      ln -s /morpheus/logs/zookeeper /var/log/zookeeper
      chmod 777 /morpheus/logs/zookeeper
    #    chown -R hduser:hadoop /morpheus/logs/hadoop
    fi

    apt-get -y install $PACKAGES

    chown -R zookeeper:zookeeper /morpheus/logs/zookeeper

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

installHadoop(){
  groupadd --system hadoop
  useradd hduser -m -d /home/hduser -s /bin/bash --system -g hadoop
  usermod -a -G hadoop zookeeper

  echo "Making .ssh directory"
  mkdir -p /home/hduser/.ssh
  echo "Changing ownership for the .ssh directory"
  chmod 0700 /home/hduser/.ssh
  chown hduser:hadoop /home/hduser/.ssh

  su -l -c 'ssh-keygen -t rsa -f /home/hduser/.ssh/id_rsa -P ""' hduser
  cat /home/hduser/.ssh/id_rsa.pub | su -l -c 'tee -a /home/hduser/.ssh/authorized_keys' hduser
  chmod 0600 /home/hduser/.ssh/authorized_keys
  chown hduser:hadoop /home/hduser/.ssh/authorized_keys

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
      echo "Expanding /tmp/$PACKAGE_NAME file"
      tar -xzf "/tmp/$PACKAGE_NAME" -C /opt
      ln -s /opt/hadoop-2.7.1 /opt/hadoop
    else
      echo "Downloaded file does not match expected checksum, expected $DOWNLOAD_CHECKSUM and got $CHECKSUM using type $DOWNLOAD_CHECKSUM_TYPE"
      exit 1
    fi
  fi

  mkdir -p /tmp/hadoop-config/
  cp -r /opt/hadoop/etc/hadoop/* /tmp/hadoop-config/
  if [ -d "/opt/hadoop/etc/hadoop" ]; then
    echo "/opt/hadoop/etc/hadoop exists so we need to clear it and soft link to the morpheus config path"
    rm -Rf /opt/hadoop/etc/hadoop
    ln -s /morpheus/config/hadoop /opt/hadoop/etc/hadoop
    cp -r /tmp/hadoop-config/* /opt/hadoop/etc/hadoop/
  fi

  if [ ! -d "/home/hduser/hdfs-data" ]; then
    echo "/home/hduser/hdfs-data doesn't exist so create it"
    ln -s /morpheus/data /home/hduser/hdfs-data
    chown -R hduser:hadoop /morpheus/data
  fi

  if [ ! -d "/opt/hadoop/logs" ]; then
    echo "/opt/hadoop/logs doesn't exist so create it"
    ln -s /morpheus/logs/hadoop /opt/hadoop/logs
    chmod 777 /morpheus/logs/hadoop
    chown -R hduser:hadoop /morpheus/logs/hadoop
  fi

  if [ ! -d "/var/log/zookeeper" ]; then
    echo "/var/log/zookeeper doesn't exist so create it"
    ln -s /morpheus/logs/zookeeper /var/log/zookeeper
    chmod 777 /morpheus/logs/zookeeper
  fi
}

configure(){
  case "$OS_RELEASE" in
   ubuntu)
    if [ -f /tmp/ssh-config ]; then
      echo "Backing up ssh-config file..."
      mv /home/hduser/.ssh/config /home/hduser/.ssh/config.orig
      echo "Moving ssh-config file into place..."
      mv /tmp/ssh-config /home/hduser/.ssh/config
      chmod 0600 /home/hduser/.ssh/config
      chown hduser:hadoop /home/hduser/.ssh/config
      chown -R hduser:hadoop /home/hduser
    else
      echo "ssh-config file not found at /tmp/ssh-config"
      exit 1
    fi

    if [ -f /tmp/bashrc ]; then
      echo "Backing up bashrc file..."
      mv /home/hduser/.bashrc /home/hduser/.bashrc.orig
      echo "Moving bashrc file into place..."
      mv /tmp/bashrc /home/hduser/.bashrc
      chmod 0777 /home/hduser/.bashrc
      chown hduser:hadoop /home/hduser/.bashrc
      chown -R hduser:hadoop /home/hduser
    else
      echo "bashrc file not found at /tmp/bashrc"
      exit 1
    fi

    if [ -f /tmp/profile ]; then
      echo "Backing up profile file..."
      mv /home/hduser/.profile /home/hduser/.profile.orig
      echo "Moving profile file into place..."
      mv /tmp/profile /home/hduser/.profile
      chmod 0777 /home/hduser/.profile
      chown hduser:hadoop /home/hduser/.profile
      chown -R hduser:hadoop /home/hduser
    else
      echo "profile file not found at /tmp/profile"
      exit 1
    fi

    if [ -f /tmp/core-site.xml ]; then
      echo "Backing up core-site.xml file..."
      cp /morpheus/config/hadoop/core-site.xml /morpheus/config/hadoop/core-site.xml.orig
      echo "Moving core-site.xml file into place..."
      mv /tmp/core-site.xml /morpheus/config/hadoop/core-site.xml
      chmod 0777 /morpheus/config/hadoop/core-site.xml
    else
      echo "core-site.xml file not found at /tmp/core-site.xml"
      exit 1
    fi

    if [ -f /tmp/yarn-site.xml ]; then
      echo "Backing up yarn-site.xml file..."
      cp /morpheus/config/hadoop/yarn-site.xml /morpheus/config/hadoop/yarn-site.xml.orig
      echo "Moving yarn-site.xml file into place..."
      mv /tmp/yarn-site.xml /morpheus/config/hadoop/yarn-site.xml
      chmod 0777 /morpheus/config/hadoop/yarn-site.xml
    else
      echo "yarn-site.xml file not found at /tmp/yarn-site.xml"
      exit 1
    fi

    if [ -f /tmp/mapred-site.xml ]; then
      echo "Backing up mapred-site.xml file..."
      cp /morpheus/config/hadoop/mapred-site.xml /morpheus/config/hadoop/mapred-site.xml.orig
      echo "Moving mapred-site.xml file into place..."
      mv /tmp/mapred-site.xml /morpheus/config/hadoop/mapred-site.xml
      chmod 0777 /morpheus/config/hadoop/mapred-site.xml
    else
      echo "mapred-site.xml file not found at /tmp/mapred-site.xml"
      exit 1
    fi

    if [ -f /tmp/hdfs-site.xml ]; then
      echo "Backing up hdfs-site.xml file..."
      cp /morpheus/config/hadoop/hdfs-site.xml /morpheus/config/hadoop/hdfs-site.xml.orig
      echo "Moving hdfs-site.xml file into place..."
      mv /tmp/hdfs-site.xml /morpheus/config/hadoop/hdfs-site.xml
      chmod 0777 /morpheus/config/hadoop/hdfs-site.xml
    else
      echo "hdfs-site.xml file not found at /tmp/hdfs-site.xml"
      exit 1
    fi

    if [ -f /morpheus/config/hadoop/hadoop-env.sh ]; then
      echo "Backing up hadoop-env.sh file..."
      cp /morpheus/config/hadoop/hadoop-env.sh /morpheus/config/hadoop/hadoop-env.sh.orig
      echo "Modifying hadoop-env.sh file..."
      sed -i "/export JAVA_HOME=/c\export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64/" /morpheus/config/hadoop/hadoop-env.sh
    else
      echo "hadoop-env.sh file not found at /morpheus/config/hadoop/hadoop-env.sh"
      exit 1
    fi

    echo "One more time for good measure"
    chown -R hduser:hadoop /home/hduser
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
installHadoop
stat
configure
stat

