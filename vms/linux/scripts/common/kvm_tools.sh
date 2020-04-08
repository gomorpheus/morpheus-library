#!/bin/bash -e
set -e
. /tmp/os_detect.sh


case "$OS_RELEASE" in
  ubuntu)
	apt-get -y install qemu-guest-agent
        ;;

  centos|rhel|ol)
  	yum install qemu-guest-agent -y
   	;;
  opensuse-leap)
    zypper install -y qemu-guest-agent
    ;;
  *)
   	;;
esac

