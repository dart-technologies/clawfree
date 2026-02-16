.PHONY: help get icons clean run web demo demo-travel test test-e2e-logic test-e2e-ui test-integration test-all analyze lint check build-macos build-web build-ios build-android build-apk build-watch qa deploy stop health gateway gateway-down gateway-logs gateway-health

# Default target
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Setup & Maintenance
# ---------------------------------------------------------------------------

get: ## Get dependencies
	flutter pub get

icons: ## Regenerate all app icons from assets/icon.png
	@echo "Generating macOS icons..."
	@for size in 16 32 64 128 256 512 1024; do \
		sips -z $$size $$size assets/icon.png --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$$size.png 2>/dev/null; \
	done
	@echo "Generating WatchOS icons..."
	@mkdir -p ios/WatchCompanion/Assets.xcassets/AppIcon.appiconset
	@for size in 48 55 58 80 87 88 100 172 196 216 1024; do \
		sips -z $$size $$size assets/icon.png --out ios/WatchCompanion/Assets.xcassets/AppIcon.appiconset/icon_$$size.png 2>/dev/null; \
	done
	@echo "✅ Icons generated for all platforms."

clean: ## Clean build artifacts
	flutter clean
	cd infra && docker compose down --rmi local 2>/dev/null || true

# ---------------------------------------------------------------------------
# Run & Development
# ---------------------------------------------------------------------------

run: ## Run on macOS with API key from env
	flutter run -d macos --dart-define=ANTHROPIC_API_KEY=$(ANTHROPIC_API_KEY)

web: ## Run on Chrome (requires gateway)
	flutter run -d chrome

# ---------------------------------------------------------------------------
# Demo Scenarios (AI Trajectories)
# ---------------------------------------------------------------------------

demo: ## Run in demo mode (no API key needed)
	flutter run -d macos --dart-define=DEMO_MODE=true

demo-travel: ## Run automated Tokyo travel scenario in live app (In-App Trajectory)
	flutter run -d macos --dart-define=DEMO_MODE=true --dart-define=DEMO_SCENARIO=travel

# ---------------------------------------------------------------------------
# Quality & Testing
# ---------------------------------------------------------------------------

test: ## Run all unit tests
	flutter test

test-e2e-logic: ## Run fast logic-only E2E tests (no UI)
	flutter test test/integration/demo_trip_e2e_test.dart

test-e2e-ui: ## Run high-fidelity UI automation with voiceover (macOS only)
	flutter test integration_test/demo_driver.dart -d macos --timeout 5x

test-integration: ## Run all integration tests (logic + UI)
	flutter test test/integration/ integration_test/

record-demo: ## Record E2E UI demo to MP4 with audio (macOS + BlackHole 2ch required)
	@./scripts/record_window.sh demo_recording.mp4 1

record-demo-silent: ## Record E2E UI demo to MP4 (video only, no audio device)
	@./scripts/record_window.sh demo_recording_silent.mp4 999 2>/dev/null || true

test-all: test test-integration ## Run unit + logic + UI tests

analyze: ## Run Dart analyzer
	flutter analyze

lint: analyze ## Alias for analyze

check: lint test test-e2e-logic ## Pre-commit check (Fast path)

# ---------------------------------------------------------------------------
# Build & Distribution
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

build-watch: ## Build WatchOS companion
	xcodebuild -workspace ios/Runner.xcworkspace -scheme "WatchCompanion" -destination 'generic/platform=watchOS' build

# ---------------------------------------------------------------------------
# Simulator Management
# ---------------------------------------------------------------------------

sim-list: ## List all available simulators
	xcrun simctl list devices

sim-boot: ## Boot the iPhone and Watch simulators
	@echo "Booting iPhone+Watch..."
	@xcrun simctl boot "iPhone+Watch" 2>/dev/null || true
	@echo "Booting Apple Watch Series 11..."
	@xcrun simctl boot "94CC285A-30F3-41DD-B254-E1560AF1E167" 2>/dev/null || true
	@open -a Simulator

sim-build-watch: ## Build WatchOS companion for simulator
	@echo "Building Watch companion for simulator..."
	@xcodebuild -workspace ios/Runner.xcworkspace -scheme "WatchCompanion" -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' -derivedDataPath build/watch build > /dev/null

sim-install: ## Build and install on the "iPhone+Watch" simulator
	@echo "Building for simulator..."
	flutter build ios --simulator --no-codesign
	@echo "Installing on iPhone+Watch..."
	xcrun simctl install "iPhone+Watch" build/ios/iphonesimulator/Runner.app
	@echo "✅ Installed. iOS will sync to paired Watch automatically."

sim-install-all: ## Install the built apps on ALL booted simulators (iOS + Watch)
	@echo "Installing iOS app on booted iPhone/iPad simulators..."
	@for udid in $$(xcrun simctl list devices booted | awk '/-- iOS/ || /-- iPadOS/ { f=1 } /-- / && !(/iOS/ || /iPadOS/) { f=0 } f && /Booted/ { match($$0, /[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}/); if (RSTART > 0) print substr($$0, RSTART, RLENGTH); }'); do \
		echo "  -> $$udid"; \
		xcrun simctl install $$udid build/ios/iphonesimulator/Runner.app || echo "  ⚠️ Failed to install on $$udid"; \
	done
	@echo "Installing Watch app on booted Watch simulators..."
	@for udid in $$(xcrun simctl list devices booted | awk '/-- watchOS/ { f=1 } /-- / && !/watchOS/ { f=0 } f && /Booted/ { match($$0, /[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}/); if (RSTART > 0) print substr($$0, RSTART, RLENGTH); }'); do \
		echo "  -> $$udid"; \
		if [ -d "build/watch/Build/Products/Debug-watchsimulator/WatchCompanion.app" ]; then \
			xcrun simctl install $$udid build/watch/Build/Products/Debug-watchsimulator/WatchCompanion.app || echo "  ⚠️ Failed to install Watch app on $$udid"; \
		else \
			echo "  ⚠️ Watch app not found. Run 'make sim-build-watch' first."; \
		fi \
	done
	@echo "✅ Done."

sim-run: ## Launch the app on the iPhone+Watch simulator
	xcrun simctl launch "iPhone+Watch" art.dart.clawfree

# ---------------------------------------------------------------------------
# Infrastructure (Docker)
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

gateway: ## Start CORS gateway (Docker)
	cd infra && docker compose up -d

gateway-down: ## Stop CORS gateway
	cd infra && docker compose down

gateway-logs: ## Tail gateway logs
	cd infra && docker compose logs -f gateway

gateway-health: ## Check gateway health
	@curl -sf http://localhost:8080/api/health | python3 -m json.tool || echo "Gateway not running"
