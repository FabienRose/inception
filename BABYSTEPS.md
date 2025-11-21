# Baby Steps: Inception Project

Guide étape par étape pour construire l'infrastructure Docker Inception.

---

## Step 1: Create Basic docker-compose.yml Structure

**What to do:**
- Create `srcs/docker-compose.yml`
- Create a `services:` section (empty for now)
- Create a `networks:` section with one custom network
- Create a `volumes:` section (empty for now)

**What you need to understand:**
- Docker Compose file structure: `services`, `networks`, `volumes` are top-level keys
- Network naming: you'll create a network like `inception-network` that all containers will join
- Service names become hostnames: if you name a service `mariadb`, other containers can reach it at `mariadb` (not `localhost`)

**Example structure:**
```yaml
services:

networks:
  inception-network:
    driver: bridge

volumes:
```

---

## Step 2: Define Volumes (Host Paths)

**What to do:**
- Create two bind mount volumes:
  - One for MariaDB data: `/home/<your-login>/data/mariadb`
  - One for WordPress files: `/home/<your-login>/data/wordpress`
- Use `driver: local` with `driver_opts` for bind mounts

**What you need to understand:**
- Bind mounts map to specific host paths (required here)
- Volume persistence: data survives container restarts/deletions
- Directories will be created automatically or via Makefile

**Example structure:**
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/mariadb
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/wordpress
```

---

## Step 3: Create .env File Structure

**What to do:**
- Create `srcs/.env` file (will be gitignored)
- Define variables using the exact names that MariaDB and WordPress expect

**Required variables:**
- `MYSQL_DATABASE` - Database name
- `MYSQL_USER` - Database user
- `MYSQL_PASSWORD` - Database user password
- `MYSQL_ROOT_PASSWORD` - Database root password
- `WORDPRESS_DB_HOST=mariadb` - Database host (service name)
- `WORDPRESS_ADMIN_USER` - WordPress admin username (MUST NOT contain "admin", "Admin", "administrator", "Administrator")
- `WORDPRESS_ADMIN_PASSWORD` - WordPress admin password
- `WORDPRESS_USER` - WordPress regular user username
- `WORDPRESS_USER_PASSWORD` - WordPress regular user password
- `DOMAIN_NAME=fmixtur.42.fr` - Your domain name

**What you need to understand:**
- `env_file:` loads ALL variables from .env automatically into the container
- Security: never commit `.env` - add to `.gitignore`
- Variable names must match what services expect

**Example .env file:**
```
MYSQL_DATABASE=wordpress
MYSQL_USER=fmixtur
MYSQL_PASSWORD=secure_password_here
MYSQL_ROOT_PASSWORD=root_secure_password_here
WORDPRESS_DB_HOST=mariadb
WORDPRESS_ADMIN_USER=fmixtur_ad
WORDPRESS_ADMIN_PASSWORD=admin_secure_password
WORDPRESS_USER=fmixtur
WORDPRESS_USER_PASSWORD=user_secure_password
DOMAIN_NAME=fmixtur.42.fr
```

---

## Step 4: Create Directory Structure

**What to do:**
- Create `srcs/requirements/mariadb/` directory with `conf/` and `tools/` subdirectories
- Create `srcs/requirements/wordpress/` directory with `conf/` and `tools/` subdirectories
- Create `srcs/requirements/nginx/` directory with `conf/` subdirectory

**Directory structure:**
```
srcs/
├── .env (not committed)
├── docker-compose.yml
└── requirements/
    ├── mariadb/
    │   ├── Dockerfile
    │   ├── conf/
    │   └── tools/
    ├── wordpress/
    │   ├── Dockerfile
    │   ├── conf/
    │   └── tools/
    └── nginx/
        ├── Dockerfile
        └── conf/
```

---

## Step 5: Create MariaDB Dockerfile and Init Script

### 5.1: Create Dockerfile

**What to do:**
- Create `srcs/requirements/mariadb/Dockerfile`
- Start with `FROM debian:12` (penultimate stable, no `:latest`)
- Install MariaDB server package
- Create necessary directories and set ownership
- Copy configuration files and init script
- Expose port 3306

**Example Dockerfile:**
```dockerfile
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
```

### 5.2: Create Init Script

**What to do:**
- Create `srcs/requirements/mariadb/tools/init.sh`
- Create SQL initialization file dynamically using environment variables
- Use heredoc to create `/init.sql` with database and user creation
- Set ownership of `/init.sql` to `mysql:mysql`
- Run `mysqld` with `--user=mysql --init-file=/init.sql`
- Use `exec mysqld` to make mysqld PID 1 (required for Docker)

**Key points:**
- `--init-file`: executes SQL file only on first initialization (when `/var/lib/mysql` is empty)
- `--user=mysql`: required flag, MariaDB won't run as root
- `exec`: replaces shell process with mysqld, making it PID 1
- `set -e`: makes script exit on any error

**Example init.sh:**
```bash
#!/bin/bash
set -e

cat > /init.sql <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

chown mysql:mysql /init.sql

echo -e "${GREEN}${BOLD}Starting MariaDB...${RESET}"
exec mysqld --user=mysql --init-file=/init.sql
```

### 5.3: Add MariaDB Service to docker-compose.yml

**What to do:**
- Add `mariadb:` service
- Set `build: ./requirements/mariadb`
- Set `image: mariadb${PROJECT_NAME}` (image name format)
- Set `restart: always`
- Add volume mount for mariadb_data
- Add `env_file: .env`
- Add to `inception-network`

**Example:**
```yaml
services:
  mariadb:
    build: ./requirements/mariadb
    image: mariadb${PROJECT_NAME}
    container_name: mariadb
    restart: always
    networks:
      - inception-network
    volumes:
      - mariadb_data:/var/lib/mysql
    env_file:
      - .env
```

---

## Step 6: Create WordPress Dockerfile and Init Script

### 6.1: Create Dockerfile

**What to do:**
- Create `srcs/requirements/wordpress/Dockerfile`
- Start with `FROM debian:12`
- Install PHP-FPM and required PHP extensions (php-mysql, php-cli, etc.)
- Install WordPress CLI (wp-cli)
- Copy configuration files and init script
- Expose port 9000 (PHP-FPM default)

**Example Dockerfile:**
```dockerfile
FROM debian:12

RUN apt-get update && \
    apt-get install -y php-fpm php-mysql php-cli php-common curl && \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY conf/ /conf/

COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 9000

ENTRYPOINT ["/init.sh"]
```

### 6.2: Create Init Script

**What to do:**
- Create `srcs/requirements/wordpress/tools/init.sh`
- Download WordPress if not already installed (check for `wp-config.php`)
- Copy and configure `wp-config.php` with environment variables
- Install WordPress if not already installed (use `wp core install`)
- Create admin user (username MUST NOT contain "admin", "Admin", "administrator", "Administrator")
- Create regular user (non-admin role)
- Configure PHP-FPM to listen on 0.0.0.0:9000
- Set proper permissions
- Use `exec php-fpm8.2 -F` to make PHP-FPM PID 1

**Key points:**
- Idempotency: script should be safe to run multiple times (check if already done)
- User creation: use `wp user create` with roles (administrator, editor, etc.)
- PHP-FPM config: modify `/etc/php/8.2/fpm/pool.d/www.conf` to listen on TCP port 9000

**Example init.sh:**
```bash
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
```

### 6.3: Create wp-config.php Template

**What to do:**
- Create `srcs/requirements/wordpress/conf/wp-config.php` as a template
- Use placeholders like `${MYSQL_DATABASE}`, `${MYSQL_USER}`, etc.
- The init script will replace these placeholders with actual environment variables

**Example template:**
```php
<?php
define( 'DB_NAME', '${MYSQL_DATABASE}' );
define( 'DB_USER', '${MYSQL_USER}' );
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );
define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );
// ... rest of WordPress config
```

### 6.4: Add WordPress Service to docker-compose.yml

**What to do:**
- Add `wordpress:` service
- Set `build: ./requirements/wordpress`
- Set `restart: always`
- Add volume mount for wordpress_data
- Add `env_file: .env`
- Add `depends_on: mariadb`
- Add to `inception-network`

**Example:**
```yaml
  wordpress:
    build: ./requirements/wordpress
    image: wordpress${PROJECT_NAME}
    container_name: wordpress
    restart: always
    networks:
      - inception-network
    volumes:
      - wordpress_data:/var/www/html
    env_file:
      - .env
    depends_on:
      - mariadb
```

---

## Step 7: Create NGINX Dockerfile and Configuration

### 7.1: Create Dockerfile

**What to do:**
- Create `srcs/requirements/nginx/Dockerfile`
- Start with `FROM debian:12`
- Install nginx and openssl
- Generate self-signed SSL certificate during build (using openssl)
- Copy nginx configuration
- Remove default nginx files that might conflict
- Expose port 443
- Use `CMD ["nginx", "-g", "daemon off;"]` (no init.sh needed, nginx becomes PID 1 directly)

**Key points:**
- Certificates are generated during build, not copied from host
- No init.sh needed for nginx (unlike MariaDB and WordPress)
- `nginx -g 'daemon off;'` keeps nginx in foreground (required for Docker)

**Example Dockerfile:**
```dockerfile
FROM debian:12

# Install NGINX and OpenSSL
RUN apt-get update &&\
    apt-get upgrade -y &&\
    apt-get install -y nginx openssl

# Create SSL directory and generate self-signed certificate
RUN mkdir -p /etc/nginx/ssl &&\
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/CN=fmixtur.42.fr"

COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Remove default nginx site to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default
RUN rm -f /var/www/html/index.nginx-debian.html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

### 7.2: Create NGINX Configuration

**What to do:**
- Create `srcs/requirements/nginx/conf/default.conf`
- Configure server block listening on port 443 with SSL
- Set `server_name` to your domain (e.g., `fmixtur.42.fr`)
- Configure SSL: certificate and key paths, TLS versions (1.2 and 1.3 only)
- Set up FastCGI proxy to WordPress container on port 9000
- Configure root directory (volume mount from WordPress)
- Set `index index.php` first to prioritize WordPress

**Key points:**
- `ssl_protocols TLSv1.2 TLSv1.3;` - only TLSv1.2 and TLSv1.3 (no older versions)
- `fastcgi_pass wordpress:9000;` - forwards PHP requests to WordPress container
- Root should point to `/var/www/html` (shared volume)

**Example default.conf:**
```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name fmixtur.42.fr;

    # SSL Configuration - TLSv1.2 and TLSv1.3 only
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php index.html index.htm;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP-FPM Configuration
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

### 7.3: Add NGINX Service to docker-compose.yml

**What to do:**
- Add `nginx:` service
- Set `build: ./requirements/nginx`
- Set `restart: always`
- Add `ports: "443:443"` (expose port 443 on host)
- Add volume mount for wordpress_data (NGINX needs to serve WordPress files)
- Add `depends_on: wordpress`
- Add to `inception-network`

**Example:**
```yaml
  nginx:
    build: ./requirements/nginx
    image: nginx${PROJECT_NAME}
    container_name: nginx
    restart: always
    networks:
      - inception-network
    ports:
      - "443:443"
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - wordpress
    env_file:
      - .env
```

---

## Step 8: Configure /etc/hosts

**What to do:**
- Edit `/etc/hosts` on your VM host
- Add entry: `127.0.1.1 fmixtur.42.fr` (or your VM IP if preferred)
- This allows your domain to resolve locally

**What you need to understand:**
- `/etc/hosts`: local DNS override, maps domain names to IP addresses
- Why needed: your domain needs to resolve for TLS to work properly
- Testing: `ping fmixtur.42.fr` should resolve to 127.0.1.1

**Command:**
```bash
sudo bash -c 'echo "127.0.1.1 fmixtur.42.fr" >> /etc/hosts'
```

---

## Step 9: Create Makefile

**What to do:**
- Create `Makefile` at repo root
- Add targets for common operations:
  - `build`: build all Docker images
  - `up`: start all services
  - `down`: stop and remove containers
  - `clean`: remove containers and volumes
  - `fclean`: full clean (containers, volumes, images, and data)
  - `re`: rebuild everything from scratch
  - `logs`: show logs from all services
  - `setup-hosts`: add domain to /etc/hosts
  - `setup-dirs`: create data directories

**Key points:**
- Makefile should `cd srcs` before running docker compose commands
- `fclean` should remove data directories: `rm -rf /home/<login>/data/*`
- Use `sudo` for operations that require root (hosts, data cleanup)

**Example Makefile:**
```makefile
.PHONY: all build up down clean fclean re logs ps stop restart setup-hosts setup-dirs

all: build up

# Setup /etc/hosts entry
setup-hosts:
	@if ! grep -q "fmixtur.42.fr" /etc/hosts 2>/dev/null; then \
		echo "Adding fmixtur.42.fr to /etc/hosts (127.0.1.1)"; \
		sudo bash -c "echo \"127.0.1.1 fmixtur.42.fr\" >> /etc/hosts"; \
		echo "Entry added to /etc/hosts"; \
	else \
		echo "Entry for fmixtur.42.fr already exists in /etc/hosts"; \
	fi

# Create data directories if they don't exist
setup-dirs:
	@mkdir -p /home/fmixtur/data/mariadb /home/fmixtur/data/wordpress
	@echo "Data directories created"

build:
	cd srcs && docker compose build

up: setup-hosts setup-dirs
	cd srcs && docker compose up -d

down:
	cd srcs && docker compose down

clean: down
	cd srcs && docker compose down -v
	@echo "Containers and volumes removed"

fclean: clean
	cd srcs && docker compose down --rmi all
	sudo rm -rf /home/fmixtur/data/mariadb/* /home/fmixtur/data/wordpress/*
	@echo "Everything cleaned (containers, volumes, images, and data)"

re: fclean build up

logs:
	cd srcs && docker compose logs -f
```

---

## Step 10: Create .gitignore

**What to do:**
- Create `.gitignore` at repo root
- Add: `.env`, `*.pem`, `*.key`, `*.crt`, `srcs/.env`
- Add data directories pattern if needed

**Important:**
- Never commit secrets, passwords, or certificates
- `.env` files must be ignored

**Example .gitignore:**
```
# Environment files
.env
srcs/.env
*.env

# SSL Certificates
*.pem
*.key
*.crt

# Data directories (optional, but good practice)
/home/*/data/
```

---

## Step 11: Test and Verify

### 11.1: Build and Start

**What to do:**
- Run `make build` to build all images
- Run `make up` to start all services
- Check containers are running: `docker compose ps`

### 11.2: Verify Requirements

**Checklist:**
- ✅ All services in separate containers
- ✅ Custom Dockerfiles (no pre-built images)
- ✅ Restart policies set (`restart: always`)
- ✅ Custom network used (not `host`)
- ✅ Volumes mapped to `/home/<login>/data/`
- ✅ Port 443 only (no 80)
- ✅ TLS 1.2/1.3 only
- ✅ WordPress users created (admin without "admin" in name + 1 non-admin)
- ✅ No secrets in committed files
- ✅ Base images pinned (no `:latest`)
- ✅ No hacky loops (exec used properly)

### 11.3: Test Functionality

**What to test:**
- Access WordPress: `https://fmixtur.42.fr` (accept SSL warning)
- Login with admin user
- Create a post
- Test data persistence: `make clean` then `make up` - data should persist
- Test full cleanup: `make fclean` then `make up` - data should be fresh

---

## Common Pitfalls to Avoid

- ❌ Using `image:` instead of `build:` (you must build from Dockerfile)
- ❌ Using `network: host` (must use custom network)
- ❌ Committing `.env` or secrets to git
- ❌ Using `tail -f` or `sleep infinity` as main process
- ❌ Hardcoding passwords in Dockerfiles
- ❌ Using `:latest` tags for base images
- ❌ Exposing port 80 (only 443 allowed)
- ❌ Admin username containing "admin"
- ❌ Not setting restart policies
- ❌ Using pre-built service images from Docker Hub
- ❌ Forgetting `exec` in init scripts (makes service PID 1)

---

## Key Concepts Summary

1. **Docker Compose**: orchestrates multiple services
2. **Dockerfiles**: each service has its own, builds from base image
3. **Init scripts**: handle initialization (MariaDB, WordPress) or run service directly (nginx)
4. **Networking**: custom bridge network allows service name resolution
5. **Volumes**: bind mounts persist data on host at `/home/<login>/data/`
6. **Environment variables**: `.env` file provides secrets and configuration
7. **SSL/TLS**: self-signed certificates generated during build
8. **PID 1**: main process must be PID 1 (use `exec` or direct `CMD`)

---

## Final Notes

- **Makefile**: essential for automation and setup (hosts, directories)
- **Testing**: verify all requirements systematically
- **Documentation**: understand your setup inside and out for evaluation
- **Security**: never commit secrets, always use `.env` and `.gitignore`
