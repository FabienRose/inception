# USER_DOC.md - User Documentation

## Overview

This documentation is for end users and administrators who want to use the Inception WordPress infrastructure.

### What Services Are Provided?

The Inception stack provides a complete web hosting environment with:

- **WordPress Website** - A fully functional content management system (CMS) for creating and managing website content
- **HTTPS Support** - Secure encrypted connections to the website
- **Database** - MariaDB database for storing WordPress content and user data
- **Web Server** - NGINX web server configured as reverse proxy

### System Requirements

- Docker and Docker Compose installed on your Linux machine
- At least 2GB free disk space
- Sudo access for initial setup
- Ports 443 (HTTPS) and 3306 (database) available

---

## Getting Started

### Step 1: Configure Your Domain

The project uses a local domain name. You need to add it to your `/etc/hosts` file.

Your domain should be: `login.42.fr` (replace `login` with your username)

Example for user `fmixtur`:
```bash
sudo nano /etc/hosts
# Add this line:
127.0.0.1 fmixtur.42.fr
```

### Step 2: Create Environment Configuration

Create a `.env` file in the `srcs/` directory with your settings:

```bash
cd srcs
nano .env
```

**Required variables:**

```env
# Domain configuration
DOMAIN_NAME=fmixtur.42.fr

# Database setup
MYSQL_ROOT_PASSWORD=secure_root_password_here
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=secure_wp_password_here

# WordPress admin account
WP_ADMIN_USER=wordpress_admin
WP_ADMIN_PASSWORD=secure_admin_password_here
WP_ADMIN_EMAIL=admin@fmixtur.42.fr
```

⚠️ **Security Tips:**
- Use strong passwords (at least 12 characters, mix of uppercase, lowercase, numbers, symbols)
- Keep your `.env` file secure - never commit it to Git
- Change default usernames and passwords
- Store credentials securely

### Step 3: Start the Infrastructure

From the project root directory, run:

```bash
make
```

This will:
- Verify domain configuration in `/etc/hosts`
- Create necessary data directories
- Build Docker images
- Start all services

The first run may take several minutes as it builds the Docker images.

### Step 4: Access WordPress

Once the services are running:

1. Open your web browser
2. Navigate to: `https://fmixtur.42.fr` (use your configured domain)
3. Accept the SSL certificate warning (self-signed certificate is normal)
4. Complete the WordPress installation wizard or log in with your admin credentials

---

## Managing Services

### Start the Infrastructure

```bash
make
```

Or separately:
```bash
make build    # Build all images
make up       # Start all services
```

### Stop the Infrastructure

```bash
make down     # Stop and remove containers (data is preserved)
```

Or:
```bash
make stop     # Stop containers without removing them
```

### Restart Services

```bash
make restart           # Restart all services
make restart-nginx     # Restart only NGINX
make restart-wordpress # Restart only WordPress
make restart-mariadb   # Restart only MariaDB
```

### Check Service Status

```bash
make ps
```

Output shows:
- Container names
- Current status (running, exited, restarting)
- Port mappings
- Resource usage

---

## Accessing Administration Panels

### WordPress Admin Panel

1. Navigate to: `https://fmixtur.42.fr/wp-admin/`
2. Log in with your admin username and password (from `.env`)
3. Manage posts, pages, themes, plugins, users

### No Direct Database Access

By default, the database is not accessible from outside the Docker network for security reasons. Only WordPress can connect to the database.

---

## Managing Credentials & Sensitive Data

### Where Are Credentials Stored?

- **Environment Variables**: `srcs/.env` (Git-ignored)
- **Secrets Directory**: `secrets/` folder (Git-ignored) for sensitive files

### Security Practices

✅ **DO:**
- Keep `.env` and `secrets/` folder out of Git
- Use `.gitignore` to prevent accidental commits
- Rotate passwords regularly
- Use strong, unique passwords

❌ **DON'T:**
- Share your `.env` file
- Commit credentials to Git
- Use default passwords in production
- Store credentials in unencrypted files on shared systems

### Updating Credentials

To change passwords:

1. Edit `srcs/.env` with new credentials
2. Run `make fclean` to clean up existing containers and data
3. Run `make` to start fresh with new credentials

⚠️ **Warning**: `make fclean` deletes all data (database and website files)!

---

## Checking Service Health

### View Live Logs

See real-time activity from all services:

```bash
make logs              # All services
make logs-nginx        # NGINX only
make logs-wordpress    # WordPress only
make logs-mariadb      # MariaDB only
```

### Common Issues

**Issue: Website shows connection error**
- Verify NGINX is running: `make ps`
- Check NGINX logs: `make logs-nginx`
- Verify domain in `/etc/hosts`
- Accept SSL certificate warning in browser

**Issue: WordPress can't connect to database**
- Verify MariaDB is running: `make ps`
- Check MariaDB logs: `make logs-mariadb`
- Verify credentials in `srcs/.env` match database setup
- Verify WordPress container can reach MariaDB

**Issue: Port 443 already in use**
- Check what's using port 443: `sudo lsof -i :443`
- Stop other services or choose different port in `.env`

**Issue: Permission denied errors**
- Ensure you have sudo access for directory creation
- Check data directory permissions: `ls -la /home/login/data/`

---

## Data Backup & Recovery

### Data Persistence

Two volumes store persistent data:

- **WordPress Files**: `/home/login/data/wordpress/` - website content
- **Database**: `/home/login/data/mariadb/` - WordPress database

Data persists even when containers are stopped.

### Backing Up Data

```bash
# Backup WordPress files
cp -r /home/login/data/wordpress/ ~/backup_wordpress_$(date +%Y%m%d)

# Backup database
cp -r /home/login/data/mariadb/ ~/backup_mariadb_$(date +%Y%m%d)
```

### Cleaning Up

```bash
make clean      # Removes containers and volumes (deletes data)
make fclean     # Full cleanup including images and local data directories
```

⚠️ **Warning**: These commands delete all data. Backup first if needed!

---

## Maintenance Tasks

### Update Services

To apply updates or changes:

```bash
make re         # Complete rebuild from scratch
```

This is equivalent to: `make fclean && make build && make up`

### Regular Maintenance

- **Weekly**: Check logs for errors: `make logs`
- **Monthly**: Verify WordPress and plugin updates
- **Monthly**: Review user accounts and access
- **Quarterly**: Clean up old database backups
- **As Needed**: Update MariaDB or PHP versions in Dockerfiles

---

## Troubleshooting Guide

| Problem | Solution |
|---------|----------|
| Services won't start | Run `make fclean && make` to rebuild |
| Database connection fails | Verify credentials in `.env` |
| Website shows 502 Bad Gateway | Check WordPress container: `make logs-wordpress` |
| NGINX won't start | Verify port 443 is free: `sudo lsof -i :443` |
| Data not persisting | Verify volume directories exist: `ls /home/login/data/` |
| SSL certificate warnings | Expected - accept the self-signed certificate in browser |
| Can't access admin panel | Verify WordPress container is running: `make ps` |

For detailed debugging, always check:
```bash
make ps                # Service status
make logs              # All logs
docker ps -a           # All containers (including stopped)
```

---

## Getting Help

- Check service logs: `make logs`
- View all available commands: Running `make help` (if available)
- Review the main [README.md](README.md) for technical details
- Check Docker documentation: https://docs.docker.com/
