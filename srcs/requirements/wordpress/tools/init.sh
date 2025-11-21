#!/bin/bash
set -e

if [ ! -f /var/www/html/wp-config.php ]; then
    echo -e "${ORANGE}${BOLD}Downloading WordPress...${RESET}"
    wp core download --path=/var/www/html --allow-root
fi

cp /conf/wp-config.php /var/www/html/wp-config.php

# Replace placeholders in wp-config.php with environment variables
sed -i "s|\${MYSQL_DATABASE}|${MYSQL_DATABASE}|g" /var/www/html/wp-config.php
sed -i "s|\${MYSQL_USER}|${MYSQL_USER}|g" /var/www/html/wp-config.php
sed -i "s|\${MYSQL_PASSWORD}|${MYSQL_PASSWORD}|g" /var/www/html/wp-config.php
sed -i "s|\${WORDPRESS_DB_HOST}|${WORDPRESS_DB_HOST}|g" /var/www/html/wp-config.php

# Install WordPress if not already installed
if ! wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then
    echo -e "${ORANGE}${BOLD}Installing WordPress...${RESET}"
    wp core install \
        --path=/var/www/html \
        --url=https://${DOMAIN_NAME} \
        --title="Inception" \
        --admin_user=${WORDPRESS_ADMIN_USER} \
        --admin_password=${WORDPRESS_ADMIN_PASSWORD} \
        --admin_email=admin@${DOMAIN_NAME} \
        --skip-email \
        --allow-root
fi

# Create additional user if it doesn't exist (required: 1 admin + 1 non-admin)
if ! wp user get ${WORDPRESS_USER} --path=/var/www/html --allow-root --field=ID 2>/dev/null; then
    echo -e "${ORANGE}${BOLD}Creating user ${WORDPRESS_USER}...${RESET}"
    wp user create \
        ${WORDPRESS_USER} \
        ${WORDPRESS_USER}@${DOMAIN_NAME} \
        --user_pass=${WORDPRESS_USER_PASSWORD} \
        --path=/var/www/html \
        --role=editor \
        --allow-root
fi

chown -R www-data:www-data /var/www/html
sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf

echo -e "${GREEN}${BOLD}Starting PHP-FPM...${RESET}"
exec php-fpm8.2 -F