#!/bin/bash -eu
. /tmp/os_detect.sh

if [ -z "$DOWNLOAD_URL" ]; then
  echo "No DOWNLOAD_URL was set in environment, this should be set in Packer."
  exit 1
else
  PACKAGE_NAME=${DOWNLOAD_URL##*/}
  echo "Downloading $PACKAGE_NAME from $DOWNLOAD_URL"
  wget -q -O "/tmp/$PACKAGE_NAME" "$DOWNLOAD_URL"
fi

case "$OS_RELEASE" in
 ubuntu)
	if [ -f "/tmp/erlang" ]; then
		cp /tmp/erlang /etc/apt/preferences.d/erlang
	fi

	if [ -f "/tmp/$PACKAGE_NAME" ]; then
	  dpkg -i "/tmp/$PACKAGE_NAME"
	  apt-get update
	  apt-get -y install socat
	  apt-get -y install erlang-nox
	fi

  ;;

centos|rhel|ol)
  echo "Not supported yet"
  ;;
 *)
  ;;
esac
