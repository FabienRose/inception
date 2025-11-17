# Baby Steps: Inception Project

Starting from docker-compose.yml creation, step by step.

---

## Step 1: Create Basic docker-compose.yml Structure

**What to do:**
- Create `srcs/docker-compose.yml`
- Define the version (use `version: '3.8'` or `version: '3'`)
- Create a `services:` section (empty for now)
- Create a `networks:` section with one custom network
- Create a `volumes:` section (empty for now)

**What you need to understand:**
- Docker Compose file structure: `version`, `services`, `networks`, `volumes` are top-level keys
- Network naming: you'll create a network like `inception` that all containers will join
- Service names become hostnames: if you name a service `mariadb`, other containers can reach it at `mariadb` (not `localhost`)

**Learning resources:**
- Docker Compose file reference: understand the basic YAML structure
- Docker networking basics: containers on the same network can communicate by service name

---

## Step 2: Define the Custom Network

**What to do:**
- In `networks:` section, define a network (e.g., `inception`)
- Set driver to `bridge` (default, but explicit is good)
- Optionally set a subnet (e.g., `172.20.0.0/16`)

**What you need to understand:**
- Bridge networks: default Docker network type, containers can communicate by name
- Why not `host`: `host` network bypasses Docker networking and breaks service name resolution
- Network isolation: containers on this network can talk to each other, but not to containers on other networks

**Example structure:**
```yaml
networks:
  inception:
    driver: bridge
```

---

## Step 3: Define Volumes (Host Paths)

**What to do:**
- Create two bind mount volumes:
  - One for MariaDB data: `/home/<your-login>/data/mariadb`
  - One for WordPress files: `/home/<your-login>/data/wordpress`
- Use `type: bind` and `bind: create_host_path: true` (or create directories manually)

**What you need to understand:**
- Bind mounts vs named volumes: bind mounts map to specific host paths (required here)
- Volume persistence: data survives container restarts/deletions
- Permissions: ensure directories are readable/writable by containers (may need `chmod`)

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

## Step 4: Create .env File Structure

**What to do:**
- Create `srcs/.env` file (will be gitignored)
- Define variables using the exact names that MariaDB and WordPress expect
- Variables you'll need:
  - Database name (`MYSQL_DATABASE`)
  - Database user (`MYSQL_USER`)
  - Database root password (`MYSQL_ROOT_PASSWORD`)
  - Database user password (`MYSQL_PASSWORD`)
  - WordPress admin username (NOT containing "admin")
  - WordPress admin password
  - WordPress user password
  - Domain name (`login.42.fr`)

**What you need to understand:**
- `env_file:` loads ALL variables from .env automatically into the container
- Your .env must use the exact variable names that services expect (e.g., `MYSQL_ROOT_PASSWORD` for MariaDB)
- Security: never commit `.env` - add to `.gitignore`
- Simple approach: just list all variables in .env, services will read them automatically

**Example .env file:**
```
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=secure_password_here
MYSQL_ROOT_PASSWORD=root_secure_password_here
WORDPRESS_DB_HOST=mariadb
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=secure_password_here
WP_ADMIN_USER=manager
WP_ADMIN_PASSWORD=admin_secure_password
WP_USER=editor
WP_USER_PASSWORD=user_secure_password
DOMAIN_NAME=login.42.fr
```

---

## Step 5: Add MariaDB Service Skeleton

**What to do:**
- Add `mariadb:` service to `services:` section
- Set `build:` pointing to `./requirements/mariadb` (where Dockerfile will be)
- Set `image: mariadb` (image name must match service name - requirement!)
- Set `container_name:` (e.g., `mariadb`)
- Set `restart: unless-stopped` or `restart: always`
- Add `networks:` with your custom network
- Add `volumes:` mapping the mariadb_data volume to `/var/lib/mysql` inside container
- Add `env_file:` section pointing to `.env`

**What you need to understand:**
- `build:` vs `image:`: `build` tells Compose to build from Dockerfile, `image` names the built image (required: image name == service name)
- Environment variables: MariaDB uses specific env vars like `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
- `env_file:` loads all variables from `.env` automatically - make sure your .env has the exact variable names MariaDB expects
- Volume mount: `/var/lib/mysql` is where MariaDB stores its data files
- Network assignment: container joins your custom network so WordPress can reach it

**Example structure:**
```yaml
services:
  mariadb:
    build: ./requirements/mariadb
    image: mariadb
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

## Step 6: Add WordPress Service Skeleton

**What to do:**
- Add `wordpress:` service
- Set `build:` pointing to `./requirements/wordpress`
- Set `image: wordpress` (image name must match service name - requirement!)
- Set `container_name:`, `restart:`, `networks:` (same network as mariadb)
- Add `volumes:` mapping wordpress_data to `/var/www/html` (WordPress root)
- Add `env_file:` pointing to `.env`
- Add `depends_on:` with `mariadb` (WordPress needs DB to be ready)

**What you need to understand:**
- WordPress environment variables: `WORDPRESS_DB_HOST=mariadb` (service name!), `WORDPRESS_DB_NAME`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`
- `env_file:` loads all variables from `.env` automatically - make sure your .env has WordPress variables
- `depends_on:`: ensures mariadb starts before wordpress, but doesn't wait for DB to be ready (you may need healthchecks later)
- Volume mount: `/var/www/html` is the WordPress document root
- Service name as hostname: `WORDPRESS_DB_HOST=mariadb` works because both are on the same network

**Example structure:**
```yaml
  wordpress:
    build: ./requirements/wordpress
    image: wordpress
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

## Step 7: Add NGINX Service Skeleton

**What to do:**
- Add `nginx:` service
- Set `build:` pointing to `./requirements/nginx`
- Set `image: nginx` (image name must match service name - requirement!)
- Set `container_name:`, `restart:`, `networks:`
- Add `ports:` mapping `443:443` (host:container) - this exposes port 443 on host
- Add `volumes:` to mount WordPress files (NGINX needs to serve them)
- Add `depends_on:` with `wordpress` (NGINX needs WordPress to be running)
- **Note:** NGINX config files and SSL certificates are copied into the image during build (in Dockerfile), NOT mounted as volumes

**What you need to understand:**
- Port mapping: `443:443` means host port 443 maps to container port 443
- NGINX as reverse proxy: NGINX receives requests and forwards them to PHP-FPM in WordPress container
- WordPress files volume: NGINX needs access to WordPress files to serve them (shared volume)
- Config files and SSL certs: These are copied into the image during Docker build, not mounted at runtime
- This approach is simpler and matches the project structure (configs in `conf/`, certs in `tools/`)

**Example structure:**
```yaml
  nginx:
    build: ./requirements/nginx
    image: nginx
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
```

---

## Step 8: Create Directory Structure

**What to do:**
- Create `srcs/requirements/mariadb/` directory
- Create `srcs/requirements/wordpress/` directory
- Create `srcs/requirements/nginx/` directory
- In each, create subdirectories: `conf/` and `tools/`
- Create `srcs/requirements/tools/` for shared scripts

**What you need to understand:**
- Build context: when Docker builds, the `context:` path becomes the build context (all files in that directory are available)
- Directory organization: separate configs, tools, and Dockerfiles for each service
- `.dockerignore`: you'll create these to exclude unnecessary files from build context

---

## Step 9: Create MariaDB Dockerfile

**What to do:**
- Create `srcs/requirements/mariadb/Dockerfile`
- Start with `FROM debian:12` or `FROM alpine:3.18` (penultimate stable)
- Install MariaDB server package
- Create necessary directories
- Copy any config files or init scripts
- Expose port 3306 (MariaDB default)
- Set up entrypoint/CMD to run `mysqld` properly

**What you need to understand:**
- Base image choice: Debian vs Alpine (Debian is easier for beginners, Alpine is smaller)
- Package installation: use `apt-get` (Debian) or `apk` (Alpine)
- Entrypoint vs CMD: entrypoint runs the main process, CMD provides default args
- PID 1 requirement: `mysqld` should be PID 1, not a shell script with `tail -f`
- MariaDB initialization: first run creates system databases if `/var/lib/mysql` is empty

**Learning resources:**
- MariaDB official Dockerfile examples (for reference, not to copy)
- Dockerfile best practices: minimize layers, use specific versions

---

## Step 10: Create WordPress Dockerfile

**What to do:**
- Create `srcs/requirements/wordpress/Dockerfile`
- Start with base image (Debian or Alpine)
- Install PHP-FPM and required PHP extensions (mysql, mysqli, etc.)
- Install WordPress CLI (wp-cli) - helpful for automation
- Download WordPress core files
- Copy custom scripts for WordPress setup
- Set up PHP-FPM configuration
- Expose port 9000 (PHP-FPM default port for FastCGI)
- Set CMD to run `php-fpm` in foreground

**What you need to understand:**
- PHP-FPM: FastCGI Process Manager, handles PHP execution separately from web server
- PHP extensions: WordPress needs `mysqli` or `pdo_mysql` to connect to MariaDB
- WordPress installation: can be done via wp-cli or manual file copy + database setup
- User creation: you'll need scripts to create the admin user (without "admin" in name) and regular user
- PHP-FPM pool config: configure it to listen on a socket or TCP port (9000)

**Learning resources:**
- PHP-FPM configuration: understand pool configuration files
- wp-cli documentation: commands for installing WordPress, creating users

---

## Step 11: Create NGINX Dockerfile

**What to do:**
- Create `srcs/requirements/nginx/Dockerfile`
- Start with base image (Debian or Alpine)
- Install NGINX
- Copy custom NGINX configuration files from `conf/` directory
- Copy SSL certificates from `tools/certs/` directory
- Expose port 443
- Set CMD to run `nginx` in foreground mode (`nginx -g 'daemon off;'`)

**What you need to understand:**
- NGINX foreground mode: `daemon off;` keeps NGINX in foreground (required for Docker)
- Configuration files: Copy from `conf/` to `/etc/nginx/conf.d/` in the image
- SSL certificates: Copy from `tools/certs/` to `/etc/nginx/ssl/` in the image (NOT mounted as volumes)
- This approach bakes configs and certs into the image during build

**Example Dockerfile structure:**
```dockerfile
FROM debian:12

RUN apt-get update && apt-get install -y nginx

# Copy NGINX configuration
COPY conf/ /etc/nginx/conf.d/

# Copy SSL certificates
COPY tools/certs/ /etc/nginx/ssl/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

**Learning resources:**
- NGINX configuration: server blocks, SSL directives, FastCGI proxy settings

---

## Step 12: Create NGINX Configuration

**What to do:**
- Create `srcs/requirements/nginx/conf/default.conf` or similar
- Configure server block listening on port 443
- Set `server_name` to your domain (`login.42.fr`)
- Configure SSL: certificate and key paths, TLS versions (1.2 and 1.3 only)
- Set up FastCGI proxy to WordPress container on port 9000
- Configure root directory (will be a volume mount from WordPress)

**What you need to understand:**
- Server blocks: each `server {}` block defines a virtual host
- SSL configuration: `ssl_certificate` and `ssl_certificate_key` point to your cert files
- TLS protocols: `ssl_protocols TLSv1.2 TLSv1.3;` (no TLSv1.0, TLSv1.1, or plain HTTP)
- FastCGI proxy: `fastcgi_pass wordpress:9000;` forwards PHP requests to WordPress container
- `fastcgi_param`: passes necessary variables (SCRIPT_FILENAME, etc.) to PHP-FPM

**Learning resources:**
- NGINX FastCGI proxying documentation
- NGINX SSL/TLS configuration

---

## Step 13: Generate SSL Certificates

**What to do:**
- Create script or manual command to generate self-signed certificate
- Use `openssl` to create:
  - Private key
  - Certificate signing request (CSR)
  - Self-signed certificate
- Set Common Name (CN) to `login.42.fr`
- Save key and cert in `srcs/requirements/nginx/tools/certs/` or similar
- Ensure files are readable by NGINX container

**What you need to understand:**
- Self-signed vs CA-signed: self-signed certs work but browsers show warnings (acceptable for this project)
- Certificate validity: set appropriate expiration (e.g., 365 days)
- Key security: private key must be kept secure, never committed to git
- Certificate details: CN must match the domain you're using

**Learning resources:**
- OpenSSL command-line tool: `openssl req`, `openssl x509`
- Certificate generation tutorials

---

## Step 14: Configure /etc/hosts

**What to do:**
- Edit `/etc/hosts` on your VM host
- Add entry: `<your-vm-ip> login.42.fr`
- Find your VM's IP: `hostname -I` or `ip addr show`

**What you need to understand:**
- `/etc/hosts`: local DNS override, maps domain names to IP addresses
- Why needed: your domain needs to resolve to your VM's IP for TLS to work
- Testing: `ping login.42.fr` should resolve to your VM IP

---

## Step 15: Create WordPress Setup Scripts

**What to do:**
- Create script in `srcs/requirements/wordpress/tools/` to:
  - Wait for MariaDB to be ready (check connection)
  - Install WordPress if not already installed (check for `wp-config.php`)
  - Create admin user (username without "admin" in it)
  - Create regular user
  - Set proper permissions

**What you need to understand:**
- WordPress installation: can use wp-cli (`wp core install`) or manual database setup
- User creation: `wp user create` command with roles (administrator, subscriber, etc.)
- Database readiness: script should retry connecting to MariaDB until it's ready
- Idempotency: script should be safe to run multiple times (check if already done)

**Learning resources:**
- wp-cli commands: `wp core install`, `wp user create`, `wp option update`

---

## Step 16: Create MariaDB Init Scripts (if needed)

**What to do:**
- If MariaDB's default initialization isn't enough, create custom init scripts
- Scripts in `/docker-entrypoint-initdb.d/` run on first initialization
- May need to create additional databases or users

**What you need to understand:**
- MariaDB initialization: scripts in `/docker-entrypoint-initdb.d/` execute only on first run (when data directory is empty)
- SQL scripts: can be `.sql` files or executable scripts
- Order matters: scripts execute in alphabetical order

---

## Step 17: Test Basic docker-compose.yml

**What to do:**
- Run `docker-compose config` to validate YAML syntax
- Run `docker-compose build` to build all images
- Check for build errors, fix them
- Don't start containers yet if Dockerfiles aren't complete

**What you need to understand:**
- `docker-compose config`: validates and shows final configuration (with env vars resolved)
- `docker-compose build`: builds all images defined in compose file
- Build context: ensure all referenced files exist in build contexts

---

## Step 18: Create .gitignore

**What to do:**
- Create `.gitignore` at repo root
- Add: `.env`, `secrets/`, `srcs/.env`, `*.pem`, `*.key`, `*.crt`
- Add data directories: `/home/<login>/data/` (or use pattern)

**What you need to understand:**
- Security: never commit secrets, passwords, certificates, or private keys
- `.gitignore` patterns: use wildcards and directory patterns

---

## Step 19: Create Makefile Targets

**What to do:**
- Create `Makefile` at repo root
- Add targets:
  - `build`: build all Docker images
  - `up` or `start`: start all services
  - `down` or `stop`: stop all services
  - `clean`: remove containers, volumes (careful!)
  - `re`: rebuild and restart
  - `logs`: show logs from all services

**What you need to understand:**
- Makefile syntax: targets, dependencies, commands
- Docker Compose commands: `docker-compose up -d`, `docker-compose down`, etc.
- Working directory: Makefile should `cd srcs` before running docker-compose commands

**Example structure:**
```makefile
all: build up

build:
	cd srcs && docker-compose build

up:
	cd srcs && docker-compose up -d

down:
	cd srcs && docker-compose down

clean: down
	cd srcs && docker-compose down -v
	rm -rf /home/<login>/data/*

re: clean build up

logs:
	cd srcs && docker-compose logs -f
```

---

## Step 20: Test End-to-End

**What to do:**
- Run `make build` or `make up`
- Check containers are running: `docker ps`
- Check logs: `docker-compose logs` or `make logs`
- Test HTTPS connection: `curl -k https://login.42.fr` (use `-k` to ignore self-signed cert warning)
- Access WordPress in browser: `https://login.42.fr` (accept security warning)

**What you need to understand:**
- Container status: `docker ps` shows running containers, `docker ps -a` shows all
- Logs debugging: check each service's logs for errors
- Network connectivity: containers should be able to reach each other by service name
- TLS verification: self-signed certs cause browser warnings (expected)

---

## Step 21: Verify Requirements

**What to do:**
- Check all requirements from subject:
  - ✅ All services in separate containers
  - ✅ Custom Dockerfiles (no pre-built images)
  - ✅ Restart policies set
  - ✅ Custom network used
  - ✅ Volumes mapped to `/home/<login>/data/`
  - ✅ Port 443 only (no 80)
  - ✅ TLS 1.2/1.3 only
  - ✅ WordPress users created (admin without "admin" in name)
  - ✅ No secrets in committed files

**What you need to understand:**
- Evaluation criteria: 42 projects are evaluated against specific requirements
- Testing checklist: verify each requirement systematically

---

## Step 22: Handle Edge Cases

**What to do:**
- Test container crashes: `docker kill <container>` - should restart automatically
- Test data persistence: stop containers, restart, data should persist
- Test network isolation: containers should only communicate via custom network
- Test dependency order: stop MariaDB, WordPress should handle it gracefully

**What you need to understand:**
- Restart policies: `unless-stopped` vs `always` vs `on-failure`
- Health checks: may need to add healthchecks for proper `depends_on` behavior
- Graceful degradation: services should handle dependencies not being ready

---

## Key Concepts to Master

1. **Docker Compose YAML structure**: services, networks, volumes, environment variables
2. **Docker networking**: how containers communicate by service name on custom networks
3. **Volume mounts**: bind mounts vs named volumes, persistence, permissions
4. **Environment variables**: `.env` files, variable substitution in Compose files
5. **Dockerfile basics**: FROM, RUN, COPY, EXPOSE, CMD, ENTRYPOINT
6. **NGINX configuration**: server blocks, SSL/TLS, FastCGI proxying
7. **PHP-FPM**: how it works, configuration, communication with web server
8. **MariaDB setup**: initialization, user creation, database setup
9. **WordPress installation**: wp-cli, database connection, user management
10. **SSL certificates**: generation, configuration, self-signed vs CA-signed

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

---

## Next Steps After Basics

Once you have the basic structure working:
1. Add healthchecks for better dependency management
2. Optimize Dockerfile layers (reduce image size)
3. Add proper error handling in scripts
4. Test with different base images (Alpine vs Debian)
5. Document your setup process
6. Prepare for evaluation (know your setup inside and out)

