#!/bin/bash -eux
. /tmp/os_detect.sh

case "$OS_RELEASE" in
  ubuntu)
   apt-get -y install virtualbox-guest-dkms
   ;;
  rhel|centos|ol)
   yum -y install dkms

		echo "Installing Virtualbox Guest Additions"
		mount -o loop,ro /home/cloud-user/VBoxGuestAdditions.iso /mnt/
		/mnt/VBoxLinuxAdditions.run --nox11 || :
		umount /mnt/

		echo "showing /var/log/VBoxGuestAdditions.log"
		cat /var/log/VBoxGuestAdditions.log
		echo "showing /var/log/vboxadd-install.log"
		cat /var/log/vboxadd-install.log
   ;;
  *)
   ;;
esac
