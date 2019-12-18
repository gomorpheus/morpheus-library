FROM mysql/mysql-server:5.7.24

RUN mkdir -p /etc/mysql/conf.d \
  && mkdir -p /etc/mysql/mysql.conf.d \
  && echo "[mysqld]" >> /etc/mysql/my.cnf \
  && echo "datadir=/var/lib/mysql/data" >> /etc/mysql/my.cnf \
	&& echo "socket=/var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf \
  && echo "[client]" >> /etc/mysql/my.cnf \
  && echo "socket=/var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf \
  && echo "!includedir /etc/mysql/conf.d/" >> /etc/mysql/my.cnf \
  && echo "!includedir /etc/mysql/mysql.conf.d/" >> /etc/mysql/my.cnf

COPY morpheus-entrypoint.sh /docker-entrypoint-initdb.d/morpheus-entrypoint.sh

CMD ["mysqld"]
