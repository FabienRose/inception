#!/bin/bash
set -e

cat > /init.sql <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
echo -e "${ORANGE}${BOLD}SQL Initialization Completed${RESET}"

chown mysql:mysql /init.sql

echo -e "${GREEN}${BOLD}Starting MariaDB...${RESET}"
exec mysqld --user=mysql --init-file=/init.sql