# Local Proxy

Standalone machine-level Traefik proxy for local development.

This repository exists so all projects on a machine can share one reverse proxy instead of each project starting its own.

## What this gives you

- one shared Traefik container for the whole machine
- one shared Docker network: `traefik-proxy`
- project-specific local domains such as:
  - `app.octopus.localhost.test`
  - `cms.octopus.localhost.test`
  - `landing.octopus.localhost.test`
- one dashboard for debugging routing: `http://localhost:8080`

## How it works

```mermaid
flowchart LR
    Browser[Browser]
    DNS[Wildcard DNS or /etc/hosts]
    Proxy[shared-local-proxy<br/>Traefik]
    Network[Docker network<br/>traefik-proxy]

    Browser -->|app.project.localhost.test| DNS
    DNS --> Proxy
    Proxy --> Network

    Network --> App[Project app service]
    Network --> CMS[Project CMS service]
    Network --> Landing[Project landing service]

    App -. labels .-> Proxy
    CMS -. labels .-> Proxy
    Landing -. labels .-> Proxy
```

## Canonical names

- container: `shared-local-proxy`
- network: `traefik-proxy`
- repo: `opkod-france/local-proxy`

## Prerequisites

- Docker Desktop or a running Docker daemon
- permission to bind to port `80`
- wildcard DNS for `*.localhost.test` via `dnsmasq`, or explicit `/etc/hosts` entries

## Recommended local path

Clone this repository anywhere you keep shared local infrastructure. Example:

```bash
git clone https://github.com/opkod-france/local-proxy.git ~/projects/infra/local-proxy
```

All examples below assume:

```text
~/projects/infra/local-proxy
```

## Files in this repo

- `docker-compose.yml` - shared Traefik stack
- `dnsmasq/localhost.test.conf` - wildcard DNS example
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
- port `8080` is published

Traefik dashboard:

- `http://localhost:8080`

## Wildcard DNS with dnsmasq

Preferred setup:

```conf
address=/.localhost.test/127.0.0.1
```

The example config is in:

- `dnsmasq/localhost.test.conf`

If you do not use wildcard DNS, add explicit `/etc/hosts` entries for each project domain.

## How projects should use this proxy

Projects should not run their own Traefik container.

Each project should:

1. join the external Docker network `traefik-proxy`
2. expose Traefik labels on app services
3. route through domains like `app.<project>.localhost.test`

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

Either:

- configure `dnsmasq` for `*.localhost.test`
- or add the domain to `/etc/hosts`

### Multiple Traefik containers exist

You should have only one shared proxy. Remove project-owned or stale Traefik containers and keep only `shared-local-proxy`.
