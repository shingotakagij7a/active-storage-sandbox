# Make targets leveraging docker compose for convenience.
# usage:
#   make build        # docker compose build (development)
#   make up           # build + up (detached)
#   make run          # foreground (non-detached)
#   make logs         # tail logs
#   make down         # stop
#   make prod-build   # build production image
#   make prod-run     # run production container (RAILS_MASTER_KEY required)

COMPOSE ?= docker compose
SERVICE ?= web
PORT    ?= 3000
IMAGE_NAME ?= active-storage-sandbox

.PHONY: build up run logs down restart prod-build prod-run clean images

build:
	@echo "[BUILD] compose build (development)"
	$(COMPOSE) build $(SERVICE)

up: build
	@echo "[UP] starting (detached)"
	$(COMPOSE) up -d $(SERVICE)

run: build
	@echo "[RUN] starting (foreground)"
	$(COMPOSE) up $(SERVICE)

logs:
	$(COMPOSE) logs -f $(SERVICE)

down:
	$(COMPOSE) down

restart: down up

prod-build:
	@echo "[BUILD] production image"
	docker build -t $(IMAGE_NAME):latest --build-arg RAILS_ENV=production .

prod-run: prod-build
	@if [ -z "$$RAILS_MASTER_KEY" ]; then echo "RAILS_MASTER_KEY not set" >&2; exit 1; fi
	@echo "[RUN] production container"
	docker run --rm -e RAILS_MASTER_KEY=$$RAILS_MASTER_KEY -p $(PORT):3000 $(IMAGE_NAME):latest

images:
	@docker images | grep $(IMAGE_NAME) || true

clean:
	@echo "[CLEAN] remove dev containers + dangling images"
	-$(COMPOSE) down -v || true
	-docker image prune -f >/dev/null 2>&1 || true
