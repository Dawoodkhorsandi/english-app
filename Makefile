.PHONY: get analyze test format build-apk run clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

get: ## Install dependencies
	flutter pub get

analyze: ## Run static analysis
	flutter analyze

test: ## Run all tests
	flutter test

format: ## Format all Dart files
	dart format .

format-check: ## Check formatting (CI)
	dart format --output=none --set-exit-if-changed .

build-apk: ## Build Android APK (debug)
	flutter build apk --debug

build-apk-release: ## Build Android APK (release)
	flutter build apk --release

build-ios: ## Build iOS (no codesign)
	flutter build ios --no-codesign

run: ## Run on connected device
	flutter run

clean: ## Clean build artifacts
	flutter clean
	rm -rf build/

upgrade: ## Upgrade dependencies
	flutter pub upgrade

outdated: ## Check for outdated packages
	flutter pub outdated
