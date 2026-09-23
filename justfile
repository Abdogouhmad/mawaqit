set shell := ["bash", "-uc"]

default: run

# Install dependencies
deps:
    flutter pub get

# Run the app on a connected device/emulator
run:
    flutter run

# Clean the build output
clean:
    flutter clean

# Run on the Linux desktop (no Android device/emulator needed)
run-linux:
    flutter run -d linux

run-release:
    flutter run --release

# Build debug APK
build:
    flutter build apk --debug

# Build release APK
build-release:
    flutter build apk --release

# Create an APK for each Android ABI
split:
    flutter build apk --split-per-abi

# Regenerate the home-widget Glance code (run after editing lib/src/home_widget/prayer_widget.dart)
widget:
    dart run home_widget_cli:home_widget generate -i lib/src/home_widget

# Signed release build: regenerate the widget, then build.sh (split arm/arm64 + universal APKs, signed, under dist/)
release: clean widget deps
    ./build.sh

# Generate a release keystore and print the MAWAQIT_* secrets for GitHub
keygen:
    ./build.sh --keygen

# Regenerate the built-in adhan tones (assets/audio + android res/raw)
tones:
    python3 tool/gen_tones.py

# Analyze code
analyze:
    flutter analyze

# Run all tests
test:
    flutter test

# Check Flutter environment / toolchain
doctor:
    flutter doctor -v

# All checks: analyze + format + test
check: analyze
    dart format --output=none --set-exit-if-changed lib test
    just test
