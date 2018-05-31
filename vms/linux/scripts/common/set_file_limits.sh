#!/bin/bash -eux

. /tmp/os_detect.sh

echo '* nofile soft $FILE_ULIMIT_SOFT' >> /etc/security/limits.conf
echo '* nofile hard $FILE_ULIMIT_HARD' >> /etc/security/limits.conf

echo 'fs.file-max = $FILE_LIMIT' > /etc/sysctl.d/90-file-limits.conf

case "$OS_RELEASE" in
ubuntu)
  apt-get install -y git wget curl vim unzip
	if [[ ${OS_VERSION%.*} < 15 ]] || [[ ${OS_VERSION%.*} -eq 15 && ${OS_VERSION##.*} < 10 ]]
	then
		initctl start procps
	else
		systemctl start procps
	fi
  ;;
centos|rhel)
  . /etc/init.d/functions
	apply_sysctl
	;;
*)
	;;
esac
