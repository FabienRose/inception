FROM debian:12

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y mariadb-server 

RUN mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY conf/ /etc/mysql/mariadb.conf.d/

COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 3306

ENTRYPOINT ["/init.sh"]
