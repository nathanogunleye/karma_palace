clean:
	flutter clean

pub-get: clean
	flutter pub get

pub-build: pub-get
	flutter pub run build_runner build --delete-conflicting-outputs

lint: pub-build
	flutter analyze

test: lint
	flutter test test/*

build-appbundle:
	flutter build appbundle

build-ipa:
	flutter build ipa

build-web:
	flutter build web

.PHONY: build
build:
	flutter pub run build_runner build --delete-conflicting-outputs

upgrade:
	flutter pub upgrade

outdated:
	flutter pub outdated