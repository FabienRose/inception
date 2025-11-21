.PHONY: all build up down clean fclean re logs ps stop restart setup-hosts setup-dirs

# Default target
all: build up

# Setup /etc/hosts entry for fmixtur.42.fr
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

# Build all images
build:
	cd srcs && docker compose build

# Start all services
up: setup-hosts setup-dirs
	cd srcs && docker compose up -d

# Stop all services (containers stay, can restart)
stop:
	cd srcs && docker compose stop

# Stop and remove containers (volumes and images stay)
down:
	cd srcs && docker compose down

# Stop, remove containers, and remove volumes (WARNING: deletes all data)
clean: down
	cd srcs && docker compose down -v
	@echo "Containers and volumes removed"

# Full clean: containers, volumes, and images (WARNING: deletes everything)
fclean: clean
	cd srcs && docker compose down --rmi all
	sudo rm -rf /home/fmixtur/data/mariadb/* /home/fmixtur/data/wordpress/*
	@echo "Everything cleaned (containers, volumes, images, and data)"

# Rebuild everything from scratch
re: fclean build up

# Show logs
logs:
	cd srcs && docker compose logs -f

# Show logs for specific service
logs-mariadb:
	cd srcs && docker compose logs -f mariadb

logs-wordpress:
	cd srcs && docker compose logs -f wordpress

logs-nginx:
	cd srcs && docker compose logs -f nginx

# Show running containers
ps:
	cd srcs && docker compose ps

# Restart all services
restart: stop up

# Restart specific service
restart-mariadb:
	cd srcs && docker compose restart mariadb

restart-wordpress:
	cd srcs && docker compose restart wordpress

restart-nginx:
	cd srcs && docker compose restart nginx

# Execute commands in containers
exec-mariadb:
	cd srcs && docker compose exec mariadb bash

exec-wordpress:
	cd srcs && docker compose exec wordpress bash

exec-nginx:
	cd srcs && docker compose exec nginx bash

# Clean only data (keeps containers running)
clean-data:
	sudo rm -rf /home/fmixtur/data/mariadb/* /home/fmixtur/data/wordpress/*
	@echo "Data directories cleaned (containers still running)"

# Clean only MariaDB data
clean-mariadb-data:
	sudo rm -rf /home/fmixtur/data/mariadb/*
	@echo "MariaDB data cleaned"

# Clean only WordPress data
clean-wordpress-data:
	sudo rm -rf /home/fmixtur/data/wordpress/*
	@echo "WordPress data cleaned"

# Show help
help:
	@echo "Available targets:"
	@echo "  make / make all     - Build and start all services"
	@echo "  make setup-hosts    - Add fmixtur.42.fr to /etc/hosts (auto-detects IP)"
	@echo "  make setup-dirs     - Create data directories"
	@echo "  make build          - Build all Docker images"
	@echo "  make up             - Start all services (includes setup-hosts and setup-dirs)"
	@echo "  make stop           - Stop all services (containers stay)"
	@echo "  make down           - Stop and remove containers (volumes stay)"
	@echo "  make clean          - Remove containers and volumes (WARNING: deletes data)"
	@echo "  make fclean         - Full clean: containers, volumes, images, and data"
	@echo "  make re             - Rebuild everything from scratch"
	@echo "  make logs           - Show logs from all services"
	@echo "  make logs-<service> - Show logs for specific service (mariadb/wordpress/nginx)"
	@echo "  make ps             - Show running containers"
	@echo "  make restart        - Restart all services"
	@echo "  make restart-<svc> - Restart specific service"
	@echo "  make exec-<svc>     - Open bash in specific container"
	@echo "  make clean-data     - Clean data directories (containers stay)"
	@echo "  make clean-<svc>-data - Clean data for specific service"

