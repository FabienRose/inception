*This project has been created as part of the 42 curriculum by fmixtur.*

## Description

Inception is a System Administration project that aims to broaden knowledge of Docker by virtualizing a complete web infrastructure. The project involves creating and configuring multiple Docker containers that work together to form a functional WordPress hosting environment.

The infrastructure consists of:
- **NGINX** - Web server with TLS encryption
- **WordPress + php-fpm** - Content management system
- **MariaDB** - Database server

All services run in dedicated containers, communicate through a Docker network, and store persistent data using Docker named volumes.

## Instructions

### Prerequisites

- Linux Virtual Machine (as required by the project)
- Docker and Docker Compose installed
- `make` command available
- Appropriate permissions to create directories in `/home/login/data/`

### Setup and Execution

1. **Clone or navigate to the project directory:**
   ```bash
   cd /path/to/inception
   ```

2. **Configure your domain name** (add to `/etc/hosts`):
   ```bash
   sudo nano /etc/hosts
   # Add: 127.0.0.1 fmixtur.42.fr
   ```

3. **Configure environment variables:**
   ```bash
   # Create srcs/.env file with your configuration
   nano srcs/.env
   # Required variables: DOMAIN_NAME, MYSQL_ROOT_PASSWORD, MYSQL_PASSWORD, MYSQL_USER, WP_ADMIN_PASSWORD, etc.
   ```

5. **Build and start the infrastructure:**
   ```bash
   make
   ```

6. **Access the WordPress website:**
   - Open your browser and navigate to `https://fmixtur.42.fr`
   - Accept the self-signed certificate warning

7. **Stop the infrastructure:**
   ```bash
   make down
   ```

8. **Clean up (remove containers and volumes):**
   ```bash
   make clean
   ```

### Makefile Commands

The Makefile provides convenient commands for managing the infrastructure:

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build and start all services (default target) |
| `make build` | Build all Docker images from Dockerfiles |
| `make up` | Start all services with automatic host setup and directory creation |
| `make down` | Stop and remove containers (volumes and images remain) |
| `make stop` | Stop all running services without removing containers |
| `make clean` | Remove containers and volumes (WARNING: deletes all database and WordPress data) |
| `make fclean` | Full cleanup: removes containers, volumes, images, and data directories |
| `make re` | Complete rebuild from scratch (equivalent to `make fclean build up`) |
| `make logs` | View real-time logs from all services |
| `make logs-mariadb` | View MariaDB logs |
| `make logs-wordpress` | View WordPress logs |
| `make logs-nginx` | View NGINX logs |
| `make ps` | Show status of all running containers |
| `make restart` | Restart all services |
| `make restart-mariadb` | Restart MariaDB container |
| `make restart-wordpress` | Restart WordPress container |
| `make restart-nginx` | Restart NGINX container |
| `make exec-mariadb` | Open bash shell in MariaDB container |
| `make exec-wordpress` | Open bash shell in WordPress container |
| `make exec-nginx` | Open bash shell in NGINX container |
| `make clean-data` | Delete all data (containers remain running) |
| `make clean-mariadb-data` | Delete MariaDB data only |
| `make clean-wordpress-data` | Delete WordPress data only |
| `make setup-hosts` | Add domain name to `/etc/hosts` |
| `make setup-dirs` | Create data directories in `/home/fmixtur/data/` |
| `make help` | Display help message with all available commands |

## Directory Structure

```
inception/
├── Makefile                          # Main orchestration file
├── README.md                         # This file
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # Developer documentation
└── srcs/
    ├── .env                          # Environment variables (Git ignored)
    ├── docker-compose.yml            # Docker Compose configuration
    └── requirements/
        ├── nginx/                    # NGINX service
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── default.conf
        │   └── tools/
        ├── wordpress/                # WordPress service
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── wp-config.php
        │   └── tools/
        │       └── init.sh
        ├── mariadb/                  # MariaDB service
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── server.cnf
        │   └── tools/
        │       └── init.sh
        ├── tools/                    # Shared tools
        └── bonus/                    # Optional bonus services
```

## Resources

### Docker Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Web Server & Security
- [NGINX Official Documentation](https://nginx.org/en/docs/)
- [TLS/SSL Configuration Guide](https://wiki.mozilla.org/Security/Server_Side_TLS)
- [OpenSSL Documentation](https://www.openssl.org/docs/)

### Databases
- [MariaDB Official Documentation](https://mariadb.com/kb/en/)
- [MySQL/MariaDB Container Best Practices](https://hub.docker.com/_/mariadb)

### WordPress & PHP
- [WordPress Official Documentation](https://wordpress.org/support/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

### Base Images
- [Alpine Linux Documentation](https://wiki.alpinelinux.org/)
- [Debian Official Documentation](https://www.debian.org/doc/)

### AI Usage

AI (GitHub Copilot) was used for the following tasks:
- **Configuration file templates**: Generation of initial NGINX configuration, MariaDB server configuration, and WordPress configuration templates
- **Shell scripts**: Writing initialization scripts for database setup and WordPress configuration
- **Dockerfile optimization**: Suggestions for multi-stage builds and best practices for reducing image size
- **Docker Compose structure**: Guidance on proper service configuration and networking setup
- **Documentation**: Assistance in structuring and formatting this README and related documentation files

All AI-generated content was thoroughly reviewed, tested, and modified to ensure accuracy, security (no credentials exposed), and compliance with project requirements.

## Key Design Choices

### Container Architecture
- **Separation of concerns**: Each service runs in its own container for modularity and independent scaling
- **Alpine/Debian base images**: Chosen for their small footprint and security focus
- **Custom Dockerfiles**: All images are built from scratch as per requirements

### Networking
- **Docker network**: Dedicated custom bridge network for inter-container communication
- **No host network**: Containers communicate through the Docker network for isolation
- **NGINX as single entry point**: Port 443 (HTTPS only) is the only exposed port

### Storage & Persistence
- **Docker named volumes**: Used for WordPress database and website files
- **Volume location**: `/home/fmixtur/data/` on the host machine
- **No bind mounts**: All persistent data uses Docker volumes for portability

### Security
- **Environment variables**: Sensitive configuration through `.env` file
- **Docker secrets**: Credentials stored in separate files outside Git
- **TLS encryption**: All external communication uses TLSv1.2 or TLSv1.3
- **No hardcoded credentials**: All passwords and sensitive data managed through environment variables

### Container Restart Policy
- **Always restart**: All containers have restart policies to ensure high availability
- **No infinite loops**: Services run as proper daemons, not tail -f tricks
- **PID 1 best practices**: Main processes run as PID 1 within containers

## Technology Stack Comparison

### Virtual Machines vs Docker
- **Virtual Machines**: Full OS overhead, slower startup, more resource-intensive
- **Docker**: Lightweight containerization, faster startup, shared kernel, more efficient resource usage
- **Our choice**: Docker for this project due to efficiency and portability

### Secrets vs Environment Variables
- **Environment Variables**: Simple configuration management, visible in process listings
- **Secrets**: Enhanced security for sensitive data, isolated from environment
- **Our approach**: Using environment variables in `.env` file for all configuration

### Docker Network vs Host Network
- **Docker Network**: Better isolation, service discovery by name, built-in load balancing
- **Host Network**: Direct host access, simpler but less isolated
- **Our choice**: Docker network for security and service isolation

### Docker Volumes vs Bind Mounts
- **Docker Volumes**: Managed by Docker, driver support, better portability
- **Bind Mounts**: Direct filesystem access, easier debugging
- **Our choice**: Docker volumes for compliance with requirements and better portability
