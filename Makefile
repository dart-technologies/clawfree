.PHONY: run demo test analyze build-macos build-web gateway gateway-down gateway-logs icons clean help

# Default target
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

run: ## Run on macOS with API key from env
	flutter run -d macos --dart-define=ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY)

demo: ## Run in demo mode (no API key needed)
	flutter run -d macos --dart-define=DEMO_MODE=true

web: ## Run on Chrome (requires gateway)
	flutter run -d chrome

# ---------------------------------------------------------------------------
# Quality
# ---------------------------------------------------------------------------

test: ## Run all tests
	flutter test

analyze: ## Run Dart analyzer
	flutter analyze

check: analyze test ## Run analyzer + tests

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

build-macos: ## Build macOS release
	flutter build macos --release

build-web: ## Build web release
	flutter build web --release

# ---------------------------------------------------------------------------
# Gateway (Docker)
# ---------------------------------------------------------------------------

gateway: ## Start CORS gateway (Docker)
	cd infra && docker compose up -d

gateway-down: ## Stop CORS gateway
	cd infra && docker compose down

gateway-logs: ## Tail gateway logs
	cd infra && docker compose logs -f gateway

gateway-health: ## Check gateway health
	@curl -sf http://localhost:18789/health | python3 -m json.tool || echo "Gateway not running"

# ---------------------------------------------------------------------------
# Assets
# ---------------------------------------------------------------------------

icons: ## Regenerate macOS app icons from assets/icon.png
	@for size in 16 32 64 128 256 512 1024; do \
		sips -z $$size $$size assets/icon.png --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$$size.png 2>/dev/null; \
		echo "Generated $${size}x$${size}"; \
	done

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean: ## Clean build artifacts
	flutter clean
	cd infra && docker compose down --rmi local 2>/dev/null || true

get: ## Get dependencies
	flutter pub get
