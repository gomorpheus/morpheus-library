#!/bin/bash -eu

# Turn off DNS lookups for SSH
#echo "UseDNS no" >> /etc/ssh/sshd_config

# Install packages
  if [ -z $EPEL_DOWNLOAD_URL ]; then
   echo "No EPEL_DOWNLOAD_URL was set in environment, this should be set in Packer."
    exit 1
  fi
yum install -y $EPEL_DOWNLOAD_URL

  if [ -z $DRACUT_DOWNLOAD_URL ]; then
   echo "No DRACUT_DOWNLOAD_URL was set in environment, this should be set in Packer."
    exit 1
  fi
yum install -y $DRACUT_DOWNLOAD_URL

  if [ -z $PYTHON_PYGMENT_URL ]; then
   echo "No PYTHON_PYGMENT_URL was set in environment, this should be set in Packer."
    exit 1
  fi
yum install -y $PYTHON_PYGMENT_URL 

yum -y install git wget curl vim cloud-init 

rpm -qa kernel | sed 's/^kernel-//'  | xargs -I {} dracut -f /boot/initramfs-{}.img {}

if [[ $VAGRANT  =~ true || $VAGRANT =~ 1 || $VAGRANT =~ yes ]]; then

  mkdir -pm 700 /home/vagrant/.ssh
  wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
fi

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    yum -y upgrade
fi
