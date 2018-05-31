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

if [ ! -d "/morpheus/data/rabbitmq" ]; then
  echo "/morpheus/data/rabbitmq doesn't exist so create it"
  mkdir -p /morpheus/data/rabbitmq
fi
if [ ! -d "/var/lib/rabbitmq" ]; then
  echo "/var/lib/rabbitmq doesn't exist so create it"
  ln -s /morpheus/data/rabbitmq /var/lib/rabbitmq
fi

groupadd --system rabbitmq
useradd rabbitmq -d /var/lib/rabbitmq -s /bin/false --system --no-create-home -g rabbitmq

if [ ! -d "/morpheus/data/rabbitmq/mnesia" ]; then
  echo "/morpheus/data/rabbitmq/mnesia doesn't exist so create it"
  mkdir -p /morpheus/data/rabbitmq/mnesia
fi

chown -Rf rabbitmq:rabbitmq /morpheus/data/rabbitmq

if [ ! -d "/morpheus/logs/rabbitmq" ]; then
  echo "/morpheus/logs/rabbitmq doesn't exist so create it"
  mkdir -p /morpheus/logs/rabbitmq
  ln -s /morpheus/logs/rabbitmq /var/log/rabbitmq
  chown -Rf rabbitmq:rabbitmq /morpheus/logs/rabbitmq
fi

if [ ! -d "/morpheus/config" ]; then
  echo "/morpheus/config doesn't exist so create it"
  mkdir -p /morpheus/config
fi

if [ ! -d "/etc/rabbitmq" ]; then
  echo "/etc/rabbitmq doesn't exist so create it"
  ln -s /morpheus/config /etc/rabbitmq
  chown -Rf rabbitmq:rabbitmq /morpheus/config
fi

if [ -f "/tmp/$PACKAGE_NAME" ]; then
	echo "Running dpkg -i /tmp/$PACKAGE_NAME"
    dpkg -i "/tmp/$PACKAGE_NAME"
fi

echo "Running apt-get install -y rabbitmq-server"
apt-get install -y rabbitmq-server

if [ -f /tmp/entrypoint.sh ]; then
  echo "Moving entrypoint service start script into place..."
  mv /tmp/entrypoint.sh /
  chown root.root /entrypoint.sh
  chmod 755 /entrypoint.sh
else
  echo "Entrypoint service start script not found at /tmp/entrypoint.sh"
  exit 1
fi

echo "Enabling rabbitmq_management plugin"
rabbitmq-plugins enable rabbitmq_management
echo "Stopping rabbitmq-server service"
service rabbitmq-server stop
echo "Removing rabbitmq-server auto startup"
update-rc.d -f rabbitmq-server remove