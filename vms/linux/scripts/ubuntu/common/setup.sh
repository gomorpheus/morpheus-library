#!/bin/bash -eu

# Turn off DNS lookups for SSH
echo "Turning off DNS lookups for SSH"
echo "UseDNS no" >> /etc/ssh/sshd_config

if [[ $VAGRANT  =~ true || $VAGRANT =~ 1 || $VAGRANT =~ yes ]]; then
  # Add vagrant user to sudoers.
  echo "Adding vagrant user to sudoers"
  echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant

  mkdir -pm 700 /home/vagrant/.ssh
  wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
else
  # Add cloud-user user to sudoers.
  echo "Adding cloud-user user to sudoers"
  echo 'cloud-user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/cloud-user
  sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
fi

echo "Running apt-get -y update"
apt-get -y update

# Install packages
PACKAGES="cloud-init cloud-initramfs-growroot ntp ntpdate"
echo "Installing packages $PACKAGES"
apt-get -y install $PACKAGES

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "Running apt-get upgrade!"
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y upgrade
fi
