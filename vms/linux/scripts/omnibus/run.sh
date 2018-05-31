#!/bin/bash -e
set -e
. /tmp/os_detect.sh

SSH_PUB_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXGLnZXkJlJYgrzHmW3PS7ZgfFCqhnElr/Uz+vcyg2xF0Uu+I1pM07yXP/GZmbkjxPjoNo/4TwnRd0mC60P/pI+CCPWn5DDZplShYNZlwZV2WHrrvrP43sy8IVj3sMZsoDEaFAY1fGoO0fy7xAZoRi4vHwJTDkkFTSMp8vCrC6GWBHmRnBXesALdN4sLsSOFXuMamzGO8IV7LnHnZ3QjwD5GDa/f4zj23/rTvR7NFMQgnPWevR5GCWf+PJ1LKF586O9qC8FY1V0tDnPXtakLw3iGo+x7XDQCmMydxtUt3wqClJdTXxd4n/Cxr2V8BnFq1Kk7OkPGQntHHjL57HGlPM5kTpqVxxcGS9KtdHC5WlAzcQA0lVl9V+lBK8kNUeriCmKIfgTB90tgB5YuRaHgiNae3OHpgZWEI2+FiaE7WGZcdTnYnPiBKhxtURzAiv1dD6nS9xJivvHf8chs2+d/VOU6UX4Rs/GQQnQBfPKD0vaF4myaK+Jge5rzqR9SGpZR6kIx+6FKfNgAmc+E+lT4bEixtFjyI2lqH1rF+FRbIhlL1sEirLvjxsP2UNcX11nt7rY+fRTfqUbe4O33UDxEjeSm1itG/fS9ocWDIY0aZdbF4F8mIdhWu7hMAhb6v8NnPj4goyKYxZdGT/0CCLUjTtrWsdMPMIMJJfXrSSE9TXfw== root@labs-den-jenkins-master'

echo 'Setting up Jenkins Slave'
if [ ! -d /opt/jenkins-slave ]; then
	mkdir -p /opt/jenkins-slave
fi

echo 'Adding root user public key for Jenkins'
if [ ! -d /root/.ssh ]; then
	mkdir -p /root/.ssh
	chmod 700 /root/.ssh
	chown -R root.root /root/.ssh
fi

if [ ! -e /root/.ssh/authorized_keys ]; then
	echo $SSH_PUB_KEY > /root/.ssh/authorized_keys
	chmod 600 /root/.ssh/authorized_keys
	chown root.root /root/.ssh/authorized_keys
else
	echo $SSH_PUB_KEY >> /root/.ssh/authorized_keys
fi

echo 'Adding required packages...'
PACKAGES="cmake scons tar bzip2"
case "$OS_RELEASE" in
	ubuntu)
 	wget -q -O /root/omnibus-toolchain_1.1.73-1_amd64.deb https://bertramlabs-chef.s3.amazonaws.com/files/labs/omnibus/omnibus-toolchain_1.1.73-1_amd64.deb
 	dpkg -i /root/omnibus-toolchain_1.1.73-1_amd64.deb
 	apt-get -y install $PACKAGES autoconf binutils-doc bison build-essential flex gettext ncurses-dev devscripts dpkg-dev zlib1g-dev fakeroot binutils gnupg
 	;;

	centos|rhel|ol)
		if [[ $OS_VERSION =~ ^6 ]]; then
			wget -q -O /root/omnibus-toolchain-1.1.73-1.el6.x86_64.rpm https://bertramlabs-chef.s3.amazonaws.com/files/labs/omnibus/omnibus-toolchain-1.1.73-1.el6.x86_64.rpm
			rpm -i /root/omnibus-toolchain-1.1.73-1.el6.x86_64.rpm
		elif [[ $OS_VERSION =~ ^7 ]]; then
			wget -q -O /root/omnibus-toolchain-1.1.73-1.el7.x86_64.rpm https://bertramlabs-chef.s3.amazonaws.com/files/labs/omnibus/omnibus-toolchain-1.1.73-1.el7.x86_64.rpm
			rpm -i /root/omnibus-toolchain-1.1.73-1.el7.x86_64.rpm
		fi
		yum -y install PACKAGES autoconf bison flex gcc gcc-c++ gettext kernel-devel make cmake m4 ncurses-devel patch rpm-build zlib-devel
		;;
 	*)
		;;
esac

set +e
echo 'Creating user omnibus...'
grep -q omnibus /etc/passwd
if [ $? -eq 1 ]; then
	groupadd -g 1502 omnibus
	useradd -d /home/omnibus -m -s /opt/omnibus-toolchain/bin/bash -u 1502 -g omnibus omnibus
fi
set -e

echo 'Setting up Omnibus...'
if [ ! -d /var/cache/omnibus ]; then
	mkdir -p /var/cache/omnibus
	chmod 755 /var/cache/omnibus
	chown omnibus:omnibus /var/cache/omnibus
fi

echo 'Updating GIT configuration...'
if [ ! -e /home/omnibus/.gitconfig ]; then
	mv /tmp/gitconfig /home/omnibus/.gitconfig
	chmod 644 /home/omnibus/.gitconfig
	chown omnibus:omnibus /home/omnibus/.gitconfig
fi

if [ -x /opt/omnibus-toolchain/bin/git ]; then
	/opt/omnibus-toolchain/bin/git config --global http.sslCAinfo /opt/omnibus-toolchain/embedded/ssl/certs/cacert.pem
else
	echo "Failed to find GIT in the Omnibus embedded path at: /opt/omnibus-toolchain/bin/git"
	exit 1
fi

echo "Turn off StrictHostKeyChecking for github.com (SSH)"
if [ -e /etc/ssh/ssh_config ]; then
	echo "Host github.com\n\tStrictHostKeyChecking no" >> /etc/ssh/ssh_config
fi

echo "Ensure SSH_AUTH_SOCK is added to sudo environment"
if [ -e /etc/sudoers ]; then
	echo "Defaults env_keep+=SSH_AUTH_SOCK" >> /etc/sudoers
fi

echo 'Adding RPM signing script...'
if [ ! -e /home/omnibus/sign-rpm ]; then
	mv /tmp/sign-rpm /home/omnibus/sign-rpm
	chmod 755 /home/omnibus/sign-rpm
	chown omnibus:omnibus /home/omnibus/sign-rpm
fi

echo 'Installing GO version 1.4.2'
if [ ! -d /usr/local/go-1.4.2 ]; then
	wget -q -O /usr/local/go1.4.2.linux-amd64.tar.gz https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz
	if [ -e /usr/local/go1.4.2.linux-amd64.tar.gz ]; then
		if [ ! -d /usr/local/go-1.4.2 ]; then
			mkdir -p /usr/local/go-1.4.2
		fi
		tar zxf /usr/local/go1.4.2.linux-amd64.tar.gz -C /usr/local/go-1.4.2
		cd /usr/local
		rm -f go1.4.2.linux-amd64.tar.gz
		ln -s /usr/local/go-1.4.2 go
		cd /usr/local/bin/
		ln -s /usr/local/go/bin/go
		ln -s /usr/local/go/bin/godoc
		ln -s /usr/local/go/bin/gofmt
	else
		echo "Failed to download GO from https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz"
		exit 1
	fi
fi

echo 'Adding Omnibus environment script...'
if [ ! -e /home/omnibus/load-omnibus-toolchain.sh ]; then
	mv /tmp/load-omnibus-toolchain.sh /home/omnibus/load-omnibus-toolchain.sh
	chmod 755 /home/omnibus/load-omnibus-toolchain.sh
	chown omnibus:omnibus /home/omnibus/load-omnibus-toolchain.sh
fi
