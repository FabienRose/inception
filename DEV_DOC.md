# DEV_DOC.md - Developer Documentation

## Overview

This documentation is for developers and system administrators who need to build, modify, and maintain the Inception Docker infrastructure project.

---

## Development Environment Setup

### Prerequisites

Before starting, ensure you have:

- **Docker** (latest stable version)
- **Docker Compose** (v2.0 or higher)
- **Git** with proper configuration
- **Linux** (Virtual Machine as per project requirements)
- **Text editor** (VS Code, Vim, Nano, etc.)
- **Sudo access** for system configuration

### Installation Verification

```bash
# Check Docker installation
docker --version
docker compose version

# Verify Docker daemon is running
docker ps

# Check Make is available
make --version
```

### Initial Setup

1. **Clone the repository:**
```bash
git clone <repository-url>
cd inception
```

2. **Create the secrets directory:**
```bash
mkdir -p secrets
```

3. **Create environment configuration file:**
```bash
cd srcs
cat > .env << EOF
DOMAIN_NAME=yourlogin.42.fr
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=$(openssl rand -base64 12)
WP_ADMIN_USER=wp_admin_user
WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
WP_ADMIN_EMAIL=admin@yourlogin.42.fr
EOF
cd ..
```

4. **Create docker secrets (optional but recommended):**
```bash
echo "your_secure_password" > secrets/db_password.txt
echo "your_root_password" > secrets/db_root_password.txt
echo "your_admin_credentials" > secrets/credentials.txt
chmod 600 secrets/*.txt
```

5. **Add domain to /etc/hosts:**
```bash
sudo nano /etc/hosts
# Add: 127.0.0.1 yourlogin.42.fr
```

---

## Project Structure & File Organization

### Directory Layout

```
inception/
├── Makefile                           # Build automation
├── README.md                          # Main documentation
├── USER_DOC.md                        # End-user guide
├── DEV_DOC.md                         # This file
├── secrets/                           # Sensitive credentials (Git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                           # Environment variables (Git-ignored)
    ├── docker-compose.yml             # Docker Compose orchestration
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile             # NGINX image definition
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── default.conf       # NGINX configuration
        │   └── tools/                 # Helper scripts
        │
        ├── wordpress/
        │   ├── Dockerfile             # WordPress + PHP-FPM image
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── wp-config.php      # WordPress database config
        │   └── tools/
        │       └── init.sh            # WordPress initialization
        │
        └── mariadb/
            ├── Dockerfile             # MariaDB image definition
            ├── .dockerignore
            ├── conf/
            │   └── server.cnf         # MariaDB configuration
            └── tools/
                └── init.sh            # Database initialization
```

### .gitignore Requirements

Ensure these are in `.gitignore`:
```
srcs/.env
secrets/
/home/**/data/
.DS_Store
*.log
```

---

## Building & Launching the Project

### Build Process

```bash
# Build all Docker images (without starting)
make build
```

This executes:
```bash
cd srcs && docker compose build
```

**What happens:**
1. Reads `docker-compose.yml`
2. Builds `nginx` image from `requirements/nginx/Dockerfile`
3. Builds `wordpress` image from `requirements/wordpress/Dockerfile`
4. Builds `mariadb` image from `requirements/mariadb/Dockerfile`
5. Names images according to `image:` directive in compose file

### Complete Launch

```bash
# Full setup: build + start
make
# Or explicitly:
make all
```

**Sequence:**
1. Verifies domain in `/etc/hosts` (`make setup-hosts`)
2. Creates data directories (`make setup-dirs`)
3. Builds images (`make build`)
4. Starts containers (`make up`)

### Individual Service Control

```bash
# Start all services
make up

# Stop all services (keeps containers)
make stop

# Restart all services
make restart

# Stop and remove containers
make down

# Rebuild specific service
docker compose build nginx

# Start specific service
docker compose up -d wordpress
```

---

## Container & Volume Management

### Viewing Container Status

```bash
# Show running containers
make ps
# or
docker compose ps

# Show all containers (including stopped)
docker ps -a

# List all Docker images
docker images

# Inspect a specific container
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

### Accessing Container Shells

```bash
# Access NGINX container
docker compose exec nginx sh

# Access WordPress container (with bash)
docker compose exec wordpress bash

# Access MariaDB container (MySQL CLI)
docker compose exec mariadb mysql -u root -p
```

### Volume Management

```bash
# List all volumes
docker volume ls

# Inspect volume details
docker volume inspect inception-wordpress_data
docker volume inspect inception-mariadb_data

# View volume data on host
ls -la /home/login/data/wordpress/
ls -la /home/login/data/mariadb/

# Clean all volumes (DESTROYS DATA)
docker volume prune -a
```

### Network Management

```bash
# List Docker networks
docker network ls

# Inspect the inception network
docker network inspect inception-network

# Test connectivity between containers
docker compose exec wordpress ping mariadb
docker compose exec wordpress ping nginx
```

---

## Logging & Debugging

### View Service Logs

```bash
# All services, real-time follow
make logs

# Specific service
make logs-nginx
make logs-wordpress
make logs-mariadb

# Docker Compose logs
docker compose logs -f --tail=50 nginx

# Last 100 lines for WordPress
docker compose logs --tail=100 wordpress

# Logs without following
docker compose logs mariadb
```

### Debugging Containers

```bash
# Check container resource usage
docker stats

# View detailed container information
docker inspect wordpress | jq '.State'

# Check environment variables in container
docker compose exec wordpress env

# Verify network connectivity
docker compose exec nginx ping wordpress
docker compose exec wordpress ping mariadb

# Test database connection
docker compose exec wordpress mysql -h mariadb -u wordpress_user -p
```

### Common Issues & Solutions

**Issue: Container exits immediately**
```bash
docker compose logs wordpress   # Check why it exited
docker inspect wordpress --format='{{.State}}'  # Get state details
```

**Issue: Containers can't communicate**
```bash
docker compose exec nginx ping wordpress  # Test connectivity
docker network inspect inception-network  # Check network config
```

**Issue: Permission denied on volumes**
```bash
sudo ls -la /home/login/data/
sudo chown -R $(whoami) /home/login/data/
```

---

## Data & Persistence

### Where Is Data Stored?

**WordPress Files:**
- **Container**: `/var/www/html/`
- **Host**: `/home/login/data/wordpress/`
- **Volume**: `wordpress_data` (named volume)

**MariaDB Database:**
- **Container**: `/var/lib/mysql/`
- **Host**: `/home/login/data/mariadb/`
- **Volume**: `mariadb_data` (named volume)

### Accessing Data Directly

```bash
# Browse WordPress files
cd /home/login/data/wordpress/
ls -la
# View WordPress config
cat /home/login/data/wordpress/wp-config.php

# View MariaDB data
cd /home/login/data/mariadb/
ls -la
# View database files (InnoDB format)
ls databases/
```

### Data Persistence Verification

```bash
# Note some data before stopping
docker compose exec wordpress ls /var/www/html/wp-content/

# Stop containers (keeping volumes)
make stop

# Restart and verify data is still there
make up
docker compose exec wordpress ls /var/www/html/wp-content/
```

### Cleaning Up Data

```bash
# Remove containers but keep volumes (data persists)
make down

# Clean volumes (DELETES DATA)
make clean

# Full cleanup including images and local data
make fclean

# Full rebuild from scratch
make re
```

---

## Development Workflow

### Making Configuration Changes

**Example: Update NGINX configuration**

1. Edit the configuration file:
```bash
nano srcs/requirements/nginx/conf/default.conf
```

2. Rebuild the NGINX container:
```bash
docker compose build nginx
```

3. Restart the service:
```bash
docker compose restart nginx
```

4. Verify changes took effect:
```bash
docker compose exec nginx cat /etc/nginx/conf.d/default.conf
make logs-nginx
```

### Modifying Dockerfiles

**Example: Add a package to WordPress**

1. Edit the Dockerfile:
```bash
nano srcs/requirements/wordpress/Dockerfile
```

2. Rebuild:
```bash
docker compose build wordpress
```

3. Stop and start:
```bash
docker compose stop wordpress
docker compose up -d wordpress
```

4. Verify in running container:
```bash
docker compose exec wordpress <command-to-verify>
```

### Testing Changes

```bash
# Quick test: exec into container and test manually
docker compose exec nginx sh

# Within container, verify configuration
/etc/nginx/conf.d/default.conf exists
nginx -t  # Test NGINX config

# Log output to see if there are errors
docker compose logs nginx
```

---

## Environment Variables & Secrets

### Environment Variable Scope

**In `.env` file (non-sensitive):**
```env
DOMAIN_NAME=yourlogin.42.fr
PROJECT_NAME=inception
NGINX_PORT=443
MARIADB_PORT=3306
```

**Used in `docker-compose.yml`:**
```yaml
image: mariadb${PROJECT_NAME}  # Results in: mariadbinception
container_name: mariadb
ports:
  - "${MARIADB_PORT}:3306"
env_file:
  - .env
```

**Inside containers:**
```bash
docker compose exec wordpress env | grep DOMAIN_NAME
```

### Docker Secrets (for sensitive data)

**Define in docker-compose.yml:**
```yaml
secrets:
  db_password:
    file: ../secrets/db_password.txt
```

**Use in services:**
```yaml
services:
  mariadb:
    secrets:
      - db_password
    volumes:
      - /run/secrets/db_password:/etc/db_password:ro
```

**Access in container:**
```bash
docker compose exec mariadb cat /run/secrets/db_password
```

---

## Docker Compose Configuration Details

### Service Dependencies

```yaml
depends_on:
  - mariadb  # WordPress waits for MariaDB to start
```

Note: This only waits for container to start, not for the service to be ready. Health checks or init scripts verify actual readiness.

### Volume Types & Options

**Named volumes (required for this project):**
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/mariadb
```

**Container volume mounts:**
```yaml
volumes:
  - mariadb_data:/var/lib/mysql   # Named volume
  - wordpress_data:/var/www/html  # Named volume
```

Bind mounts (like `-v /host/path:/container/path`) are NOT used per project requirements.

### Network Configuration

```yaml
networks:
  inception-network:
    driver: bridge
```

All services connected to this custom bridge network. They can reach each other by hostname (service name).

---

## Useful Development Commands

```bash
# Rebuild everything from scratch
make fclean && make

# View real-time resource usage
docker stats

# Execute command in container
docker compose exec <service> <command>

# View container logs with timestamps
docker compose logs --timestamps wordpress

# Follow logs for specific service
docker compose logs -f mariadb

# Shell into container for debugging
docker compose exec wordpress /bin/bash

# Check container exit code
docker compose ps
docker inspect <container-id> -f '{{.State.ExitCode}}'

# Backup volumes before testing
tar -czf backup-volumes-$(date +%Y%m%d).tar.gz /home/login/data/

# Reset to clean state
make fclean
make
```

---

## Best Practices

✅ **DO:**
- Test changes in a container before rebuilding
- Keep `.env` and `secrets/` out of Git
- Use meaningful commit messages
- Document configuration changes
- Regularly check logs for errors
- Back up data before major changes
- Test data persistence after rebuilds

❌ **DON'T:**
- Edit files inside running containers permanently (changes lost on restart)
- Hardcode credentials in Dockerfiles or config files
- Use `docker run` instead of Docker Compose
- Pull pre-made images (except Alpine/Debian base)
- Use `latest` tag in image names
- Run containers as root unnecessarily
- Use `tail -f` or `sleep infinity` as main process

---

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Docker Guide](https://hub.docker.com/_/mariadb)
- [WordPress Docker Setup](https://wordpress.org/support/article/installing-wordpress-with-docker/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
