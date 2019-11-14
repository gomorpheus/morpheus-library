#!/bin/bash
# morpheus init to grant user privleges
set -e

echo "Morpheus MySQL entrypoint"

if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
	echo "GRANT ALL ON *.* TO '"$MYSQL_USER"'@'%';" | mysql -u root -p"${MYSQL_PASSWORD}";
fi;
