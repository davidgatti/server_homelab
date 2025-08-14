## Stage 1: Bootstrap Scaffolding
**Goal**: Add scripts and docs to provision a fresh Ubuntu environment and run docker compose.
**Success Criteria**: `scripts/bootstrap.sh` sets up Docker and runs `compose.yaml` using `.env`; `make test-fresh` works without pre-baking images.
**Tests**: Run `make test-fresh` to simulate a fresh server; verify containers start or are gated by profiles.
**Status**: In Progress

## Stage 2: Environment & Defaults
**Goal**: Provide `.env.example` with required variables and safe local defaults.
**Success Criteria**: Copying to `.env` allows `docker compose config` to succeed.
**Tests**: `cp .env.example .env && docker compose --env-file .env config` returns 0.
**Status**: Not Started

## Stage 3: Local Test Harness
**Goal**: Add a script to run the bootstrap inside `ubuntu:latest` using the host Docker socket.
**Success Criteria**: `scripts/test_fresh_ubuntu.sh` runs end-to-end without manual image modification.
**Tests**: `make test-fresh` completes and shows `docker ps` with expected containers.
**Status**: Not Started

## Stage 4: Developer UX
**Goal**: Add Makefile and README quickstart; gate hardware/media services behind profiles.
**Success Criteria**: `make up`, `make down`, `make ps` work; hardware/media services disabled by default for local tests.
**Tests**: `COMPOSE_PROFILES=hardware,media docker compose up -d` enables those services when desired.
**Status**: Not Started

