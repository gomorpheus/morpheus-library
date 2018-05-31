#!/bin/bash -eu
. /tmp/os_detect.sh

if [ -z "$GIT_HASH" ]; then
  echo "No GIT_HASH was set in environment, this should be set in Packer."
  exit 1
fi

if [ -z "$BUILD_NAME" ]; then
  echo "No BUILD_NAME was set in environment, this should be set in Packer."
  exit 1
else
	if [ -z $BUILD_TIME ]; then
	  BUILD_TIME=$(date -u +%FT%T%z)
	fi
	# sudo is not needed since the script is being called using sudo
	echo "$GIT_HASH $BUILD_NAME $BUILD_TIME" > /root/morpheus.version
	chmod 644 /root/morpheus.version

	PACKAGES="git wget curl vim unzip"
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

	mkdir -p /morpheus/config
	chmod 755 /morpheus/config
	mkdir -p /morpheus/data
	chmod 755 /morpheus/data
	mkdir -p /morpheus/logs
	chmod 755 /morpheus/logs

fi

