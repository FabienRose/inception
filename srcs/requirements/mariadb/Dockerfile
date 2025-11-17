FROM debian:12

RUN apt-get update && apt-get install -y mariadb-server

RUN mkdir -p /var/lib/mysql

COPY conf/ /etc/mysql/mariadb.conf.d/

EXPOSE 3306

CMD ["mysqld"]