.DEFAULT_GOAL := help
.PHONY: help

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1\3/p' \
	| column -t  -s ' '

clean: ## Clean generated files
	flutter clean

pub-get: clean ## Install referenced packages
	flutter pub get

pub-build: pub-get
	flutter pub run build_runner build --delete-conflicting-outputs

pub-lint: pub-build
	flutter analyze

pub-test: pub-lint
	flutter test test/*

.PHONY: test
test:
	flutter test test/*

lint:
	flutter analyze

build-appbundle:
	flutter build appbundle

build-ipa:
	flutter build ipa

# TODO: Implement
#.PHONY: deploy-ipa
#deploy-ipa: build-ipa
#	xcrun altool --validate-app --type ios --file "build/ios/ipa/LBH.ipa" --username $$APP_STORE_USERNAME --password $$APP_STORE_PASSWORD --show-progress
#	xcrun altool --upload-app --type ios --file "build/ios/ipa/LBH.ipa" --username $$APP_STORE_USERNAME --password $$APP_STORE_PASSWORD --show-progress

build-web:
	flutter build web

.PHONY: build
build: ## Build
	flutter pub run build_runner build --delete-conflicting-outputs

upgrade:
	flutter pub upgrade

outdated:
	flutter pub outdated

checkout-beta:
	git checkout FEATURE-BETA

reset-feature-beta:
	git reset --hard origin/master

force-push-beta:
	git push -f

reset-beta: checkout-beta reset-feature-beta force-push-beta

all: pub-test

refresh-tags:
	./run_tag_refresh.bash