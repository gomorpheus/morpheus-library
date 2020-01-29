#!/bin/bash -e
set -e
. /tmp/os_detect.sh


case "$OS_RELEASE" in
  ubuntu)
	apt-get -y install xe-guest-utilities
        ;;

  centos|rhel|ol)
	yum install -y debootstrap perl-Text-Templateh \
             perl-Config-IniFiles perl-File-Slurp \
             perl-File-Which perl-Data-Dumper
  	yum install qemu-guest-agent -y
  	cd /tmp
  	wget http://xen-tools.org/software/xen-tools/xen-tools-4.3.1.tar.gz
  	tar zxvf xen-tools-4.3.1.tar.gz
	cd xen-tools-4.3.1
	make install
   	;;

  *)
   	;;
esac

