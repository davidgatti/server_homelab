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

Rootless vs Rootful Docker
--------------------------
- Rootful Docker: socket path is `/var/run/docker.sock` and is owned by `root:docker`. Ensure your user is in the `docker` group or run privileged.
  - Add permissions: `sudo usermod -aG docker "$USER" && newgrp docker`
  - Or run: `TEST_PRIVILEGED=1 make test-fresh`
- Rootless Docker: socket path is `/run/user/$(id -u)/docker.sock`.
  - Use: `TEST_SOCKET=/run/user/$(id -u)/docker.sock make test-fresh`
  - You can combine with `TEST_PRIVILEGED=1` if needed.

Troubleshooting
---------------
- “command not found” when sourcing `.env`: Quote values that contain spaces, e.g. `QUAKE3_SERVER_NAME="Homelab Q3"`.
- “permission denied … docker.sock”: Use the correct socket path (see above) or add your user to the `docker` group, or run privileged.
- External network missing: `make bootstrap` creates the `${HOMELAB_NET_NAME}` network with your configured subnet/gateway.

Bootstrap Script
----------------
- `scripts/bootstrap.sh` (idempotent):
  - Installs Docker Engine + Compose if missing
  - Ensures external network `${HOMELAB_NET_NAME}` exists with the configured subnet
  - Loads `.env` and runs `docker compose up -d`

Network
-------
- Compose expects an external network named `${HOMELAB_NET_NAME}` (default `homelab`) and uses it via `networks.homelab.name`.
- The bootstrap script creates it if missing using `${HOMELAB_SUBNET}` and `${HOMELAB_GATEWAY}`.

Notes
-----
- Some services require host devices or mounts; leave profiles disabled unless your host provides them.
- `youtubed` requires a local image or a `build` context. Add one if needed.
- Adjust static IPs/MACs in `.env` to match your environment.
- Container names: Removed `container_name` entries to avoid name conflicts across environments; Compose names are now scoped by project (default `homelab`). The fresh test uses `COMPOSE_PROJECT_NAME=homelab-test` to isolate from your host stack.
