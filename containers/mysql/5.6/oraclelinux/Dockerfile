FROM mysql/mysql-server:5.6.42

RUN echo "[client]" >> /etc/my.cnf \
  && echo "socket=/var/lib/mysql/mysql.sock" >> /etc/my.cnf \
  && echo "!includedir /etc/my.cnf.d/" >> /etc/my.cnf \
  && chown -R mysql:mysql /var/lib/mysql

COPY morpheus-entrypoint.sh /docker-entrypoint-initdb.d/morpheus-entrypoint.sh

CMD ["mysqld"]
