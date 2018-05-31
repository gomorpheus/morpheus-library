#!/bin/bash -eu
. /tmp/os_detect.sh

case "$OS_RELEASE" in
 ubuntu)
  case "$JAVA_INSTALLER_VERSION" in
    7)
      add-apt-repository ppa:openjdk-r/ppa
      apt-get update
      apt-get -y install openjdk-7-jdk --force-yes
      update-java-alternatives -s java-1.7.0-openjdk-amd64
    ;;
    *)
      apt-get install -y software-properties-common
      echo "debconf shared/accepted-oracle-license-v1-1 select true" | /usr/bin/debconf-set-selections
      echo "debconf shared/accepted-oracle-license-v1-1 seen true" | /usr/bin/debconf-set-selections
      echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
      sudo apt-key add /tmp/EEA14886.asc
      apt-get update -o Dir::Etc::sourcelist="sources.list.d/webupd8team-java.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
      apt-get -y install oracle-java8-installer --force-yes
      update-java-alternatives -s java-8-oracle
    ;;
  esac
  ;;

centos|rhel|ol)
  cd /opt
  wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz"
  tar -xzf jdk-8u131-linux-x64.tar.gz
  alternatives --install /usr/bin/java java /opt/jdk1.8.0_131/bin/java 2
  alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_131/bin/jar 2
  alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_131/bin/javac 2
  alternatives --set jar /opt/jdk1.8.0_131/bin/jar
  alternatives --set javac /opt/jdk1.8.0_131/bin/javac
  echo 'export JAVA_HOME=/opt/jdk1.8.0_131' >> /etc/profile
  echo 'export JRE_HOME=/opt/jdk1.8.0_131/jre' >> /etc/profile
  echo 'export PATH=$PATH:/opt/jdk1.8.0_131/bin:/opt/jdk1.8.0_131/jre/bin' >> /etc/profile
  ;;
 *)
  ;;
esac
