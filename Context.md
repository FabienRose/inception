# context.md — Inception (42) for Cursor

## Project

- Name: Inception (42)
- Goal: Build a small Docker-based infrastructure for a WordPress website, with strict constraints, inside a VM.
- Tech stack: Docker, Docker Compose, NGINX, TLS, PHP-FPM, MariaDB, WordPress, Alpine/Debian base images.

All work is done inside a Virtual Machine, in a single Git repo, with a `srcs` directory and a `Makefile` at repo root.

---

## High-level requirements

1. Use **Docker Compose** to orchestrate multiple services.
2. Each service:
   - Runs in its **own container**.
   - Has its **own Dockerfile** (no pre-made images except base Alpine/Debian).
   - Image name == service name.
3. Containers are built from:
   - Penultimate stable **Alpine** or **Debian**.
4. **No prebuilt service images** (e.g. no `image: mariadb` from Docker Hub etc.).
5. All containers must:
   - Restart automatically on crash (`restart` policy).
   - Not rely on hacky infinite loops (`tail -f`, `sleep infinity`, `while true`, `bash` as PID1, etc.).
6. Use a **Docker network** defined in `docker-compose.yml`, not `network: host`, `--link` nor `links`.
7. Secrets / passwords:
   - No passwords or secrets in Dockerfiles or committed files.
   - Use **environment variables** and preferably `.env` and Docker **secrets**.
   - `.env` and any secrets must be **ignored by git**.

---

## Mandatory services

You must at least implement:

1. **NGINX container**
   - Acts as **sole entry point** to the infrastructure.
   - Listens on **port 443 only** on the host.
   - Must support **TLSv1.2 or TLSv1.3 only** (no plain HTTP).
   - Uses certificate/key (likely self-signed) tied to `login.42.fr` pointing to local IP.

2. **WordPress + PHP-FPM container**
   - Runs **WordPress with php-fpm only**, no NGINX inside.
   - Communicates only over the Docker network (with NGINX and MariaDB).
   - Handles initial install + configuration via env vars / scripts:
     - Ensure 2 users in DB: 1 admin (username must not contain `admin`, `Admin`, `administrator`, `Administrator`) and 1 non-admin user.

3. **MariaDB container**
   - Only MariaDB, no NGINX inside.
   - Stores WordPress DB.
   - Uses dedicated volume for DB data.
   - Credentials (root password, user, user password, DB name) must come from env/secret.

4. **Volumes**
   - Volume for **WordPress database** (MariaDB data dir).
   - Volume for **WordPress website files** (wp core, plugins, themes, uploads, etc.).
   - Both must be mapped to directories under `/home/<login>/data/` on the host.

5. **Network**
   - A custom docker network connecting all services.
   - NGINX proxies to WordPress, WordPress connects to MariaDB; no direct host access bypassing NGINX.

6. **Domain**
   - `login.42.fr` must resolve to VM’s local IP (e.g., via `/etc/hosts`).
   - Use this domain in TLS cert and in NGINX server_name.

7. **No `latest` tag**
   - Images must be pinned or built from a specific base (e.g. `debian:12`, `alpine:3.18`), not `:latest`.

---

## Repository layout (expected)

Approximate target structure:

```text
.
├── Makefile
├── secrets/           # not committed
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── ...
└── srcs/
    ├── .env           # not committed
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   └── tools/
        └──tools/     # shared scripts if needed
