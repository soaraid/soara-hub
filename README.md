# Soara Hub

This repository runs a private Docker registry using Docker Compose.

## What It Does

- Starts a self-hosted Docker registry on port `5000`
- Uses `htpasswd` basic authentication
- Persists image data in `./data`
- Stores auth credentials in `./auth/htpasswd`
- Enables image deletion and stale upload cleanup

## Requirements

- Docker
- Docker Compose

## Quick Start

1. Create the auth file and required directories:

```bash
./scripts/setup-auth.sh
```

You can also pass credentials non-interactively:

```bash
./scripts/setup-auth.sh <username> <password>
```

2. Start the registry:

```bash
docker compose up -d
```

3. Log in:

```bash
docker login localhost:5000
```

4. Tag and push an image:

```bash
docker pull nginx:alpine
docker tag nginx:alpine localhost:5000/nginx:alpine
docker push localhost:5000/nginx:alpine
```

## Project Layout

```text
.
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
curl -u <username>:<password> http://localhost:5000/v2/_catalog
```

## Configuration Notes

- `docker-compose.yml` runs `registry:2.7` as UID/GID `1000:1000`.
- `config.yml` enables delete operations and upload purging.
- The registry is configured for plain HTTP on port `5000`. For external exposure, put it behind TLS termination or a reverse proxy.

## Data and Secrets

- `auth/htpasswd` contains the registry credentials.
- `data/` contains pushed image layers and manifests.
- Both are intentionally ignored from version control.

## Maintenance

To rotate credentials, rerun:

```bash
./scripts/setup-auth.sh
```

Then restart the service:

```bash
docker compose restart registry
```
