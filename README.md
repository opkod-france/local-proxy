# Local Proxy

A standalone machine-level Traefik proxy for local development.

## Problem this solves

When multiple projects run locally, each project often tries to solve the same routing problem in its own way:

- every repo starts its own reverse proxy
- local domains are inconsistent across projects
- multiple proxies compete for port `80`
- `/etc/hosts` becomes noisy and hard to maintain
- developers need to remember different local setups for each project
- debugging local routing becomes fragmented

This repository solves that by moving local HTTP routing out of individual projects and into one shared machine-level proxy.

## What this provides

- one shared reverse proxy for the whole machine
- one shared Docker network: `traefik-proxy`
- one consistent local domain convention for every project
- one dashboard domain: `http://proxy.localhost.test`
- one place to manage boot-time startup and host-level wildcard DNS setup

## Important requirement

Wildcard local domains are a host-level DNS concern.

`dnsmasq` is **not** part of the Docker Compose stack because your browser and operating system must resolve domains such as `app.project.localhost.test` before traffic ever reaches Docker.

That means:

- Traefik runs in Docker
- wildcard DNS must be configured on the host machine
- if you do not configure host DNS, you must use explicit `/etc/hosts` entries instead

## Core idea

Projects should not run their own Traefik container.

Projects should only:

1. join the external Docker network `traefik-proxy`
2. expose Traefik labels on their services
3. choose domains such as `app.<project>.localhost.test`

This keeps project repos focused on the application, not on owning local routing infrastructure.

## How it works

```mermaid
flowchart LR
    Browser[Browser]
    DNS[Host DNS<br/>dnsmasq or /etc/hosts]
    Proxy[shared-local-proxy<br/>Traefik]
    Network[Docker network<br/>traefik-proxy]

    Browser -->|app.alpha.localhost.test| DNS
    Browser -->|api.beta.localhost.test| DNS
    Browser -->|admin.gamma.localhost.test| DNS
    Browser -->|proxy.localhost.test| DNS
    DNS --> Proxy
    Proxy --> Network

    Network --> Alpha[Project Alpha app]
    Network --> Beta[Project Beta API]
    Network --> Gamma[Project Gamma admin]

    Alpha -. labels .-> Proxy
    Beta -. labels .-> Proxy
    Gamma -. labels .-> Proxy
    Proxy -. internal router .-> Dashboard[Traefik dashboard]
```

## Canonical names

- container: `shared-local-proxy`
- network: `traefik-proxy`
- dashboard domain: `proxy.localhost.test`

## Prerequisites

- Docker Desktop or a running Docker daemon
- permission to bind to port `80`
- host-level wildcard DNS for `*.localhost.test` via `dnsmasq`, or explicit `/etc/hosts` entries

## Recommended local path

Clone this repository anywhere you keep shared local infrastructure. Example:

```bash
git clone <your-org-or-user>/local-proxy.git ~/projects/infra/local-proxy
```

All examples below assume:

```text
~/projects/infra/local-proxy
```

## Files in this repo

- `docker-compose.yml` - shared Traefik stack
- `dnsmasq/localhost.test.conf` - wildcard DNS example
- `scripts/setup-macos-dnsmasq.sh` - configure host DNS on macOS
- `scripts/setup-linux-dnsmasq.sh` - configure host DNS on Linux
- `install-macos-launchd.sh` - install boot-time startup on macOS
- `install-linux-systemd.sh` - install boot-time startup on Linux
- `launchd/com.shared-local-proxy.plist` - macOS launch agent template
- `systemd/shared-local-proxy.service` - Linux systemd user unit template

## Start the shared proxy

```bash
cd ~/projects/infra/local-proxy
docker compose up -d
```

Verify:

```bash
docker ps --filter name=shared-local-proxy --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Expected:

- `shared-local-proxy` is running
- port `80` is published

Dashboard:

- `http://proxy.localhost.test`

## Host DNS setup with dnsmasq

Preferred setup uses `dnsmasq` on the host machine, not in Docker.

Wildcard rule:

```conf
address=/.localhost.test/127.0.0.1
```

### macOS

Assumes:

- Homebrew is installed
- `dnsmasq` is installed with Homebrew

Run:

```bash
cd ~/projects/infra/local-proxy
./scripts/setup-macos-dnsmasq.sh
```

This will:

- copy the wildcard config into your Homebrew `dnsmasq.d` directory
- create `/etc/resolver/localhost.test`
- start `dnsmasq` via `brew services`

### Linux

Assumes:

- `dnsmasq` is already installed
- `systemctl` manages the service

Run:

```bash
cd ~/projects/infra/local-proxy
./scripts/setup-linux-dnsmasq.sh
```

This will:

- copy the wildcard config into `/etc/dnsmasq.d/localhost.test.conf`
- restart `dnsmasq`

### Fallback

If you do not configure `dnsmasq`, add explicit `/etc/hosts` entries for each project domain, including `proxy.localhost.test`.

## How projects integrate

Example Compose snippet:

```yaml
services:
  app:
    labels:
      - traefik.enable=true
      - traefik.http.routers.myproject-app.rule=Host(`app.myproject.localhost.test`)
      - traefik.http.services.myproject-app.loadbalancer.server.port=3000
    networks:
      - traefik-proxy

networks:
  traefik-proxy:
    external: true
```

## Boot-time startup

macOS:

```bash
cd ~/projects/infra/local-proxy
./install-macos-launchd.sh
```

Linux:

```bash
cd ~/projects/infra/local-proxy
./install-linux-systemd.sh
```

If you use a different local path, update the path in the corresponding `launchd` or `systemd` file before installing it.

## Troubleshooting

### Port 80 is already in use

Check what owns port `80`:

```bash
sudo lsof -nP -iTCP:80 -sTCP:LISTEN
```

If another proxy is already bound to port `80`, stop it or consolidate onto this repo.

### The `traefik-proxy` network already exists

That is expected on machines already using the shared model. The compose file uses it as an external network.

Check it:

```bash
docker network ls | grep traefik-proxy
```

### A project domain does not resolve

Check host DNS first. The most common failure is that `dnsmasq` is not installed or not configured on the host.

Then either:

- configure host-level `dnsmasq` for `*.localhost.test`
- or add the domain to `/etc/hosts`

### Multiple Traefik containers exist

You should have only one shared proxy. Remove project-owned or stale Traefik containers and keep only `shared-local-proxy`.
