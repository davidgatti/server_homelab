Homelab Compose — Fresh-Server Test Harness
==========================================

Goal
----
- Mimic a fresh Ubuntu server and bring up all services using a single command, without pre-baking Docker images.
- Test locally inside an `ubuntu:24.04` container before touching a real server.

Quickstart
----------
- Copy env defaults: `cp .env.example .env` and adjust IPs/credentials.
- Start locally (host): `make up` or full bootstrap: `make bootstrap`.
- Simulate a fresh server inside Ubuntu: `make test-fresh`.

Profiles
--------
- Optional services that need host devices or media mounts are gated by profiles:
  - `hardware`: Home Assistant, CUPS
  - `media`: Jellyfin, youtubed
  - `games`: Quake 3 server
- Enable by exporting `COMPOSE_PROFILES`, e.g.:
  - `COMPOSE_PROFILES=hardware,media make up`

Fresh Ubuntu Test
-----------------
- Runs `ubuntu:24.04`, mounts the host Docker socket and this repo, then executes `scripts/bootstrap.sh` with `--no-sudo`.
- This installs Docker CLI/Compose inside the ephemeral Ubuntu and uses the host Docker engine to create containers.

Bootstrap Script
----------------
- `scripts/bootstrap.sh` (idempotent):
  - Installs Docker Engine + Compose if missing
  - Ensures external network `${HOMELAB_NET_NAME}` exists with the configured subnet
  - Loads `.env` and runs `docker compose up -d`

Network
-------
- Compose expects an external network named `${HOMELAB_NET_NAME}` (default `homelab`).
- The bootstrap script creates it if missing using `${HOMELAB_SUBNET}` and `${HOMELAB_GATEWAY}`.

Notes
-----
- Some services require host devices or mounts; leave profiles disabled unless your host provides them.
- `youtubed` requires a local image or a `build` context. Add one if needed.
- Adjust static IPs/MACs in `.env` to match your environment.

