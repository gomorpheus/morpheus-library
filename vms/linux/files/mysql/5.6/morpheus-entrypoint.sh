#!/bin/bash
set -e

if [ -e "/var/opt/morpheus/vm/morpheus.env" ]; then
	source /var/opt/morpheus/vm/morpheus.env
fi

BUILD_TIME=$(date -u +%FT%T%z)
TMP_OUTPUT_FILE=$BUILD_TIME.txt
touch /tmp/$TMP_OUTPUT_FILE
echo "mysql init: " >> /tmp/$TMP_OUTPUT_FILE
echo "user - $MYSQL_USER" >> /tmp/$TMP_OUTPUT_FILE
echo "password - $MYSQL_PASSWORD" >> /tmp/$TMP_OUTPUT_FILE

get_option () {
	local section=$1
	local option=$2
	local default=$3
	ret=$(my_print_defaults $section | grep '^--'${option}'=' | cut -d= -f2-)
	IFS=$'\n' read -ra TMP_SOCKETS <<< "$ret"

	if [ ${#TMP_SOCKETS[@]} -gt 0 ]; then
		ret="${TMP_SOCKETS[0]}"
	else
    ret=$default
	fi
	echo $ret
}

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

if [ "$1" = 'mysqld' ]; then
  chmod 644 /etc/mysql/conf.d/mysql.cnf
  chmod 644 /etc/mysql/my.cnf

	service apparmor teardown
	# Get config
	DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
	SOCKET=$(get_option mysqld socket "/run/mysqld/mysqld.sock")
	ALT_SOCKET=$(get_option mysqld socket "/mysqld/mysqld.sock")
	echo "SOCKET: $SOCKET" >> /tmp/$TMP_OUTPUT_FILE
	echo "ALT_SOCKET: $ALT_SOCKET" >> /tmp/$TMP_OUTPUT_FILE
	PIDFILE=$(get_option mysqld pid-file "/run/mysqld/mysqld.pid")
	echo "PIDFILE: $PIDFILE" >> /tmp/$TMP_OUTPUT_FILE
	LOGDIR="/var/log/mysql"
	
	if [ ! -d "$DATADIR/mysql" ]; then
		if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
			echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
			echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
			exit 1
		fi

		echo "Making data directory $DATADIR" >> /tmp/$TMP_OUTPUT_FILE
		mkdir -p "$DATADIR"
		chown -R mysql:mysql "$DATADIR"
		echo "Making log directory $LOGDIR" >> /tmp/$TMP_OUTPUT_FILE
		mkdir -p "$LOGDIR"
		chown -R mysql:mysql "$LOGDIR"

		echo 'Running mysql_install_db' >> /tmp/$TMP_OUTPUT_FILE
		mysql_install_db -v --user=mysql --datadir="$DATADIR" --rpm --keep-my-cnf
		echo 'Finished mysql_install_db' >> /tmp/$TMP_OUTPUT_FILE

		mkdir -p /run/mysqld/
		chown mysql:mysql /run/mysqld
		chmod 777 /run/mysqld

		mysqld_safe -v --user=mysql --datadir="$DATADIR" --skip-networking --log-error="/var/log/mysql/setup.log" &
#		mysqld --defaults-file=/etc/mysql/my.cnf -v --user=mysql --datadir="$DATADIR" --skip-networking --log-error="/var/log/mysql/setup.log" &

		if [ -d "/run/mysqld" ]; then
			echo "/run/mysqld directory exists" >> /tmp/$TMP_OUTPUT_FILE
			ls -la /run/mysqld
		else
			echo "/run/mysqld directory does NOT exist" >> /tmp/$TMP_OUTPUT_FILE
		fi

		for i in $(seq 30 -1 0); do
			echo "checking for mysql process ==>" >> /tmp/$TMP_OUTPUT_FILE
			ps -ef | grep mysql

			echo "checking for mysqld socket ==>" >> /tmp/$TMP_OUTPUT_FILE
			echo "SOCKET $i: $SOCKET"
			if [ -e "$SOCKET" ]; then
				echo "$SOCKET exists"
			else
				echo "$SOCKET does NOT exist"
			fi
			echo "checking for alternate mysqld socket ==>"
			echo "ALT_SOCKET $i: $ALT_SOCKET"
			if [ -e "$ALT_SOCKET" ]; then
				echo "$ALT_SOCKET exists"
			else
				echo "$ALT_SOCKET does NOT exist"
			fi
			echo "ls -la /run/m* results"
			ls -la /run/mysql*

			[ -S "$SOCKET" ] && break
			[ -S "$ALT_SOCKET" ] && break
			echo 'Starting mysqld_safe process. MySQL init process in progress...' >> /tmp/$TMP_OUTPUT_FILE
			sleep 1
		done
		if [ $i = 0 ]; then
			echo >&2 'Starting mysqld_safe process. MySQL init process failed.' >> /tmp/$TMP_OUTPUT_FILE
			exit 1
		fi

		# These statements _must_ be on individual lines, and _must_ end with
		# semicolons (no line breaks or comments are permitted).
		# TODO proper SQL escaping on ALL the things D:
		echo 'Creating temp sql file' >> /tmp/$TMP_OUTPUT_FILE
		tempSqlFile=$(mktemp /tmp/mysql-first-time.XXXXXX.sql)
		cat > "$tempSqlFile" <<-EOSQL
			SET @@SESSION.SQL_LOG_BIN=0;
			
			DELETE FROM mysql.user ;
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
			DROP DATABASE IF EXISTS test ;
		EOSQL

		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" >> "$tempSqlFile"
		fi

		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" >> "$tempSqlFile"
			echo "GRANT ALL ON *.* TO '"$MYSQL_USER"'@'%' WITH GRANT OPTION ;" >> "$tempSqlFile"
		fi

		echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"
		echo 'About to run mysql temp file' >> /tmp/$TMP_OUTPUT_FILE
		mysql -h localhost -uroot mysql < "$tempSqlFile" >> /tmp/$TMP_OUTPUT_FILE
		echo 'Finished running the mysql temp file' >> /tmp/$TMP_OUTPUT_FILE

		rm -f "$tempSqlFile"
		kill $(cat $PIDFILE)
		for i in $(seq 30 -1 0); do
			[ -f "$PIDFILE" ] || break
			echo 'MySQL init process in progress...' >> /tmp/$TMP_OUTPUT_FILE
			sleep 1
		done
		if [ $i = 0 ]; then
			echo >&2 'MySQL hangs during init process.' >> /tmp/$TMP_OUTPUT_FILE
			exit 1
		fi
		echo 'MySQL init process done. Ready for start up.' >> /tmp/$TMP_OUTPUT_FILE
	fi

	chown -R mysql:mysql "$DATADIR"
	update-rc.d mysql defaults
	
	echo 'Restarting the mysql service' >> /tmp/$TMP_OUTPUT_FILE
	service mysql restart
	echo 'Starting the app armor service' >> /tmp/$TMP_OUTPUT_FILE
	service apparmor start
	echo 'begin: Catting out the tmp output file ====================='
	cat /tmp/$TMP_OUTPUT_FILE
	echo 'end :Catting out the tmp output file ====================='
else
	"$@" &
fi
