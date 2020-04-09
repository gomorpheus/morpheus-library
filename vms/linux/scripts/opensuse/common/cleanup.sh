#!/bin/bash -e
set -e
. /tmp/os_detect.sh

for nic in /etc/sysconfig/network-scripts/ifcfg-eth*;
do
  sed -i /HWADDR/d $nic;
  sed -i /UUID/d $nic;
done

sed 's/#PasswordAuthentication yes/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
unset HISTFILE
sudo find / -name "authorized_keys" -exec rm -f {} \;
# Delete unneeded files.
files=(/home/vagrant/*.sh
/home/cloud-user/*.sh
/tmp/*
/etc/udev/rules.d/70-persistent-net.rules
/lib/udev/rules.d/75-persistent-net-generator.rules
/dev/.udev/
/var/lib/dhcp/*
/var/run/*/*.pid
/var/run/*.pid
/var/log/syslog*
/var/log/messages*
/var/log/maillog*
/var/log/mail.log*
/var/log/*.log
/var/log/lastlog
/var/log/btmp*
/var/log/utmp*
/var/log/wtmp*
/root/.ssh/*
/root/.bash_history
/home/*/.bash_history
/tmp/*.json)

set +e
for f in "${files[@]}"
do
  sudo rm -rf $f
done

rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*




touch /var/log/wtmp
touch /var/log/lastlog

# Fix Huawei Xen Drivers
# echo "add_drivers+=\"xen-blkfront xen-netfront virtio_blk virtio_scsi virtio_net virtio_pci virtio_ring virtio\" " >> /etc/dracut.conf
# dracut -f /boot/initramfs-`uname -r`.img

set +e
# Zero out the rest of the free space using dd, then delete the written file.
/sbin/swapoff -a
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync
