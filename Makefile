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

appbundle:
	flutter build appbundle

ipa:
	flutter build ipa

build:
	flutter pub run build_runner build --delete-conflicting-outputs

upgrade:
	flutter pub upgrade

outdated:
	flutter pub outdated