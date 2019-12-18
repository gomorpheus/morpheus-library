FROM mysql/mysql-server:5.5.62

RUN echo "[client]" >> /etc/my.cnf \
  && echo "socket=/var/lib/mysql/mysql.sock" >> /etc/my.cnf \
  && echo "!includedir /etc/my.cnf.d/" >> /etc/my.cnf

COPY morpheus-entrypoint.sh /docker-entrypoint-initdb.d/morpheus-entrypoint.sh

CMD ["mysqld"]
