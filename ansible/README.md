# Ansible Bootstrap

This folder provides an optional facilitator layer for setting up the shared local proxy on a developer machine.

Use Ansible if you want a repeatable machine bootstrap.
Do not use it if you prefer to run the shell scripts manually.

## Scope

The Ansible playbooks handle machine setup for:

- host-level wildcard DNS via `dnsmasq`
- boot-time startup service installation
- starting the shared proxy stack

They do not manage project-specific Docker Compose services.

## Prerequisites

- Ansible installed on the host machine
- Docker already installed and running
- this repository cloned locally

## Playbooks

- `bootstrap-macos.yml`
- `bootstrap-linux.yml`

## Usage

macOS:

```bash
cd ~/projects/infra/local-proxy/ansible
ansible-playbook -i inventory/localhost.ini bootstrap-macos.yml
```

Linux:

```bash
cd ~/projects/infra/local-proxy/ansible
ansible-playbook -i inventory/localhost.ini bootstrap-linux.yml
```

## Variables

Defaults live in `group_vars/all.yml`.

You can override them with `-e`, for example:

```bash
ansible-playbook -i inventory/localhost.ini bootstrap-macos.yml -e local_proxy_repo_dir=$HOME/work/infra/local-proxy
```
