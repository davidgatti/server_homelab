.PHONY: help bootstrap up down ps logs test-fresh config validate

help:
	@echo "Targets:"
	@echo "  make bootstrap   Install Docker (if needed) and start services"
	@echo "  make up          Start services via docker compose"
	@echo "  make down        Stop services"
	@echo "  make ps          Show service status"
	@echo "  make logs        Tail logs"
	@echo "  make config      Validate compose config"
	@echo "  make test-fresh  Simulate fresh Ubuntu server via container"
	@echo "  make validate    Check env vars and IP conflicts"

bootstrap:
	./scripts/bootstrap.sh

up:
	docker compose --env-file .env -f compose.yaml up -d

down:
	docker compose --env-file .env -f compose.yaml down

ps:
	docker compose --env-file .env -f compose.yaml ps

logs:
	docker compose --env-file .env -f compose.yaml logs -f --tail=200

config:
	docker compose --env-file .env -f compose.yaml config

test-fresh:
	./scripts/test_fresh_ubuntu.sh

validate:
	./scripts/validate_env.sh
