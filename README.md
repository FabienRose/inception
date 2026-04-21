*This project has been created as part of the 42 curriculum by fmixtur.*

# Inception - Docker WordPress Infrastructure

A System Administration project that demonstrates Docker containerization by setting up a complete WordPress hosting environment with NGINX, WordPress, and MariaDB.

## Description

Inception is a Docker-based infrastructure project that creates a functional web hosting environment for WordPress. The entire infrastructure runs in isolated, interconnected Docker containers that communicate through a private Docker network and persist data using Docker named volumes.

The project teaches system administration concepts by requiring students to:
- Write custom Dockerfiles for each service (no pre-built images)
- Configure NGINX with TLS encryption (TLSv1.2 or TLSv1.3)
- Set up a WordPress installation with PHP-FPM
- Configure MariaDB as the persistent database
- Manage container orchestration with Docker Compose
- Use environment variables and secrets for secure configuration
- Implement proper container restart policies

### Architecture

The infrastructure consists of three mandatory services:

- **NGINX** - Reverse proxy and web server with TLS (HTTPS) support only
- **WordPress + php-fpm** - Content management system (without embedded NGINX)
- **MariaDB** - Relational database server (without embedded NGINX)

All containers are orchestrated using Docker Compose, run in a custom bridge network, and store persistent data using Docker named volumes (not bind mounts) in `/home/login/data/` on the host machine.

## Requirements

- Docker and Docker Compose installed
- Linux with `make` command available
- Sudo access (for `/etc/hosts` modification and data directory creation)
- Free ports 443 (HTTPS) and 3306 (database)

## Quick Start

### 1. Configure Environment Variables

Create or move a `.env` file in the `srcs/` directory:

```bash
nano srcs/.env
```

Required variables:
```env
DOMAIN_NAME=yourdomain.local
MYSQL_ROOT_PASSWORD=root_password
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com
```

### 2. Build and Start the Infrastructure

```bash
make
```

This will:
- Add your domain to `/etc/hosts`
- Create necessary data directories
- Build Docker images
- Start all containers

### 3. Access WordPress

Open your browser and navigate to `https://yourdomain.local` (replacing with your configured domain).

**Note:** You'll see a certificate warning because the project uses a self-signed SSL certificate. This is expected and safe to proceed.

## Available Commands

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build and start all services |
| `make build` | Build all Docker images |
| `make up` | Start all containers |
| `make down` | Stop and remove containers |
| `make stop` | Stop containers without removing them |
| `make restart` | Restart all services |
| `make clean` | Remove containers and volumes (deletes data) |
| `make fclean` | Full cleanup: containers, volumes, images, and local data |
| `make re` | Complete rebuild from scratch |
| `make logs` | View real-time logs from all services |
| `make logs-nginx` | View NGINX logs |
| `make logs-wordpress` | View WordPress logs |
| `make logs-mariadb` | View MariaDB logs |
| `make ps` | Show container status |

## Project Structure

```
inception/
├── Makefile                          # Infrastructure automation
├── README.md                         # This file
└── srcs/
    ├── docker-compose.yml            # Docker Compose configuration
    ├── .env                          # Environment variables (Git ignored)
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── default.conf      # NGINX configuration
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── wp-config.php     # WordPress configuration
        │   └── tools/
        │       └── init.sh           # WordPress initialization script
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            │   └── server.cnf        # MariaDB configuration
            └── tools/
                └── init.sh           # Database initialization script
```

## Troubleshooting

### Port Already in Use
If you get a "port already in use" error, check if port 443 or 3306 are already in use:
```bash
lsof -i :443
lsof -i :3306
```

### Certificate Issues
The project uses self-signed SSL certificates. This warning is normal and safe:
- In Chrome/Chromium: Click "Advanced" → "Proceed to [domain]"
- In Firefox: Click "Advanced" → "Accept the Risk and Continue"

### Database Connection Issues
If WordPress can't connect to MariaDB:
1. Ensure MariaDB container is running: `make ps`
2. Check MariaDB logs: `make logs-mariadb`
3. Verify environment variables in `srcs/.env`

### Clean Rebuild
To completely restart from scratch:
```bash
make fclean
make
```

## Related Documentation

- [Docker Official Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress Documentation](https://wordpress.org/support/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

## Design Choices & Technical Decisions

### Docker vs Virtual Machines

**Why Docker instead of VMs?**

| Aspect | Docker Containers | Virtual Machines |
|--------|------------------|------------------|
| **Startup Time** | Seconds | Minutes |
| **Resource Usage** | Minimal (shares kernel) | Heavy (full OS per VM) |
| **Isolation** | Process-level | Hardware-level |
| **Portability** | Highly portable | Less portable |
| **Development Speed** | Fast iteration | Slower workflow |

For this project, Docker provides lightweight containers that are perfect for learning infrastructure concepts without the overhead of full virtual machines.

### Docker Network vs Host Network

**Decision: Custom Bridge Network (inception-network)**

- ✅ **Isolation**: Services communicate only with each other and defined ports
- ✅ **Security**: Host services are protected from container processes
- ✅ **Flexibility**: Containers can communicate by service name (DNS resolution)
- ❌ Host Network would expose all container ports directly to the host, creating security risks

Each service reaches others using the service name (e.g., `mariadb:3306`, `wordpress:9000`), while NGINX is the only entry point exposed to the outside world on port 443.

### Docker Volumes vs Bind Mounts

**Decision: Named Volumes Only (No Bind Mounts)**

| Feature | Named Volumes | Bind Mounts |
|---------|---------------|------------|
| **Portability** | High (Docker-managed) | Low (host-dependent) |
| **Performance** | Optimized | Can be slower |
| **Permissions** | Simpler | Complex on different hosts |
| **Backup** | Easier | Manual process |
| **Recommended** | ✅ YES | ❌ NO (forbidden in this project) |

Volumes are stored in `/home/login/data/` on the host (via bind mount at storage level only, not for application use). Services access data through named volumes:
- `mariadb_data:/var/lib/mysql` - Database persistence
- `wordpress_data:/var/www/html` - Website files persistence

### Environment Variables vs Docker Secrets

**Decision: Both Used**

**Environment Variables (.env file)**
- Used for non-sensitive configuration (domain names, ports)
- Git-ignored to prevent accidental commits
- Easy to manage and understand

**Docker Secrets (recommended)**
- Used for sensitive credentials (passwords, API keys)
- More secure than environment variables
- File-based storage outside variable scope
- Mounted as read-only files in containers

Structure:
```
secrets/
├── db_root_password.txt
├── db_password.txt
└── credentials.txt
```

### Container Architecture Decisions

**One Service Per Container**
- **Separation of Concerns**: Each container has one responsibility
- **Scalability**: Services can be scaled independently
- **Maintainability**: Easier to troubleshoot and update
- **Standard Practice**: Follows Docker best practices (one process per container)

**No Infinite Loops or Daemonization**
- Services run as proper foreground processes (PID 1)
- Avoids hacky patches like `tail -f` or `sleep infinity`
- Proper signal handling for graceful shutdowns
- Containers restart via Docker restart policy (not internal loops)

**Restart Policy: Always**
- Ensures high availability
- Automatic recovery from crashes
- Production-ready behavior

## AI Usage and Attribution

This project utilized AI (GitHub Copilot) to improve productivity and reduce repetitive tasks:

**Tasks where AI was used:**
- **Configuration file generation**: Initial templates for NGINX default.conf, MariaDB server.cnf, and WordPress wp-config.php
- **Shell script writing**: Database initialization scripts and WordPress setup automation in tools/ directories
- **Dockerfile optimization**: Multi-layer builds, best practices for reducing image size, package manager efficiency
- **Docker Compose structure**: Service configuration, proper networking setup, volume management recommendations
- **Documentation**: Structure and formatting of this README and related documentation files

**How AI was applied:**
1. Generated initial templates and boilerplate code
2. All generated content was thoroughly reviewed for accuracy and security
3. Verified no hardcoded credentials were present
4. Tested configurations against project requirements
5. Ensured compliance with 42 curriculum standards

**What was NOT delegated to AI:**
- Architecture decisions and design thinking
- Security-critical configurations
- Business logic and project-specific customizations
- Deployment and testing procedures

All code and documentation has been reviewed, verified, and is fully understood and maintained by the project author.

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
