# Soara Hub

This repository runs a private Docker registry using Docker Compose.

## What It Does

- Starts a self-hosted Docker registry on port `5000` by default
- Uses `htpasswd` basic authentication
- Persists image data in `./data`
- Stores auth credentials in `./auth/htpasswd`
- Reads server-specific ports, usernames, passwords, and UI secrets from `.env`
- Enables image deletion and stale upload cleanup

## Requirements

- Docker
- Docker Compose

## Deployment Model

This repo is intended to be pushed to GitHub and deployed on multiple servers.

- Commit the code, `docker-compose.yml`, `config.yml`, and `.env.example`
- Do not commit `.env`, `auth/htpasswd`, or `data/`
- Each server keeps its own `.env`, auth file, and image data locally
- A future `git pull` updates the code, but does not overwrite that server's local `.env` or stored registry data

## Quick Start

1. Create a server-local environment file:

```bash
cp .env.example .env
```

2. Edit `.env` for that server:

```dotenv
REGISTRY_PORT=5000
REGISTRY_UI_PORT=8101
REGISTRY_LOGIN_HOST=registry.example.com
REGISTRY_USERNAME=your-registry-user
REGISTRY_PASSWORD=your-registry-password
APP_AUTH_USERNAME=operator
APP_AUTH_PASSWORD=your-ui-password
APP_SESSION_SECRET=use-a-long-random-secret
```

3. Create the auth file and required directories:

```bash
./scripts/setup-auth.sh
```

The script reads `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` from `.env`. Positional arguments still override them:

```bash
./scripts/setup-auth.sh <username> <password>
```

4. Start the registry:

```bash
docker compose up -d
```

5. Log in:

```bash
docker login <your-server-host>:<your-registry-port>
```

6. Tag and push an image:

```bash
docker pull nginx:alpine
docker tag nginx:alpine <your-server-host>:<your-registry-port>/nginx:alpine
docker push <your-server-host>:<your-registry-port>/nginx:alpine
```

## Project Layout

```text
.
|-- .env.example
|-- config.yml
|-- docker-compose.yml
`-- scripts/
    `-- setup-auth.sh
```

## Operations

Start:

```bash
docker compose up -d
```

Stop:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f registry
```

List stored repositories:

```bash
curl -u <username>:<password> http://<your-server-host>:<your-registry-port>/v2/_catalog
```

## Configuration Notes

- `docker-compose.yml` uses `.env` for deployment-specific values such as ports, credentials, container names, and UI secrets.
- `.env.example` is the tracked template. Real `.env` files stay local on each server.
- `docker-compose.yml` runs `registry:2.7` as UID/GID `1000:1000` by default.
- `config.yml` enables delete operations and upload purging.
- The registry is configured for plain HTTP on port `5000`. For external exposure, put it behind TLS termination or a reverse proxy.

## Data and Secrets

- `.env` contains per-server runtime settings and should never be committed.
- `auth/htpasswd` contains the registry credentials.
- `data/` contains pushed image layers and manifests.
- All three are intentionally ignored from version control.

## Maintenance

To rotate credentials, rerun:

```bash
./scripts/setup-auth.sh
```

Then restart the service:

```bash
docker compose restart registry
```

If you change `.env`, run:

```bash
docker compose up -d
```

That reapplies the new environment configuration without replacing your local `.env`, `auth/`, or `data/`.
