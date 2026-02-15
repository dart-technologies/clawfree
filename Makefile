.PHONY: run demo test analyze build-macos build-web build-android build-apk build-ios build-ios-dist gateway gateway-down gateway-logs icons clean help

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

demo-travel: ## Run demo mode and auto-trigger Tokyo travel flow
	flutter run -d macos --dart-define=DEMO_MODE=true --dart-define=DEMO_SCENARIO=travel

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

build-ios: ## Build iOS release (no codesign)
	flutter build ios --release --no-codesign

build-ios-dist: ## Build iOS release for distribution
	flutter build ios --release

build-android: ## Build Android release (AAB)
	flutter build appbundle --release

build-apk: ## Build Android release (APK)
	flutter build apk --release

# ---------------------------------------------------------------------------
# WatchOS Companion
# ---------------------------------------------------------------------------

build-watch: ## Build WatchOS companion (no signing, for CI)
	xcodebuild -workspace ios/Runner.xcworkspace -scheme "WatchCompanion" -destination 'generic/platform=watchOS' build CODE_SIGNING_ALLOWED=NO

build-watch-device: ## Build + install WatchOS companion to device (requires signing)
	xcodebuild -workspace ios/Runner.xcworkspace -scheme "WatchCompanion" -destination 'generic/platform=watchOS' build -allowProvisioningUpdates

# ---------------------------------------------------------------------------
# Production & QA (Docker)
# ---------------------------------------------------------------------------

qa: ## Launch Zero-to-One QA stack (Frontend + OpenClaw + Redis)
	docker compose -f infra/docker-compose.prod.yml up --build -d

deploy: qa ## Alias for qa

stop: ## Stop all Docker services and clear volumes
	docker compose -f infra/docker-compose.prod.yml down -v

health: ## Check full stack health (Gateway + Frontend)
	@echo "--- Container Health ---"
	@docker compose -f infra/docker-compose.prod.yml ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || echo "No containers running. Run: make qa"
	@echo ""
	@echo "--- Frontend (http://localhost:8080) ---"
	@curl -sf -o /dev/null -w "✅ HTTP %{http_code}\n" http://localhost:8080 || echo "❌ Offline"

# ---------------------------------------------------------------------------
# Gateway (Docker)
# ---------------------------------------------------------------------------

gateway: ## Start CORS gateway (Docker)
	cd infra && docker compose up -d

gateway-down: ## Stop CORS gateway
	cd infra && docker compose down

gateway-logs: ## Tail gateway logs
	cd infra && docker compose logs -f gateway

gateway-health: ## Check gateway health (via proxy or direct WebSocket)
	@curl -sf http://localhost:8080/api/health | python3 -m json.tool || echo "Gateway not running (try direct: docker compose -f infra/docker-compose.prod.yml exec openclaw wget -qO- http://localhost:18789/health)"

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
