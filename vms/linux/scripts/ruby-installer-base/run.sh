#!/bin/bash -eu
. /tmp/os_detect.sh

if [ -z $RUN_AS ]; then
  RUN_AS=root
fi

echo "RUN_AS: $RUN_AS"

case "$OS_RELEASE" in
 ubuntu)
  apt-add-repository -y ppa:rael-gc/rvm
  apt-get -y update
  apt-get -y install rvm
#  bash /etc/profile.d/rvm.sh
  sudo su - $USER_X -c "source /etc/profile.d/rvm.sh"
  echo "Reloading rvm"
#  bash -lc rvm reload
  sudo su - $USER_X -c "rvm reload"
  echo "Running rvm requirements"
#  bash -lc rvm requirements run
  sudo su - $USER_X -c "rvm requirements run"
  echo "Installing ruby $RUBY_VERSION via rvm"
#  bash -lc rvm install $RUBY_VERSION --default
  sudo su - $USER_X -c "rvm install $RUBY_VERSION --default"
  echo "Using ruby $RUBY_VERSION via rvm and should create gemset"
  sudo su - $USER_X -c "rvm use $RUBY_VERSION --create"
  echo "rvm installation complete"
  ;;

centos|rhel|ol)
  yum -y install gcc-c++ patch readline readline-devel zlib zlib-devel
  yum -y install libyaml-devel libffi-devel openssl-devel make
  yum -y install bzip2 autoconf automake libtool bison iconv-devel sqlite-devel
  echo "Clearing gpg db"
  rm -rf ~/.gnupg/
  echo "Installing GPG key"
#  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
#  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  curl -sSL https://rvm.io/mpapis.asc | gpg --import -
#  curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
#  curl -sSL https://raw.githubusercontent.com/wayneeseguin/rvm/master/binscripts/rvm-installer | bash -s stable
  echo "Running rvm installer"
  curl -L get.rvm.io | sudo bash -s stable
  echo "Initializing rvm"
  bash /etc/profile.d/rvm.sh
  echo "Reloading rvm"
  bash -lc rvm reload
  echo "Running rvm requirements"
  bash -lc rvm requirements run
  echo "Installing ruby $RUBY_VERSION via rvm"
  bash -lc rvm install $RUBY_VERSION
  echo "Setting ruby $RUBY_VERSION as default"
  bash -lc rvm use $RUBY_VERSION --default
  ;;
 *)
  ;;
esac
