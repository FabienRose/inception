FROM debian:12

RUN apt-get update && apt-get install -y mariadb-server

RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

COPY conf/ /etc/mysql/mariadb.conf.d/

COPY tools/init.sh /init.sh

EXPOSE 3306
ENTRYPOINT ["/init.sh"]