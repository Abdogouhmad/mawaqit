#!/usr/bin/env bash
#
# mawaqit — automated release build (Android).
#
# Builds the installable, SIGNED Android APKs and stages them flat under dist/:
#
#   Artifact                          Where it lands
#   -----------------------------------------------------------------
#   split APKs (arm / arm64)          dist/mawaqit-v<ver>-{armeabi-v7a,arm64-v8a}.apk
#   universal fat APK (arm + arm64)   dist/mawaqit-v<ver>-universal.apk   ← primary download
#   sha256 checksums                  dist/checksums.txt
#
# Release-signing is central: Android refuses to install an unsigned release
# APK (`INSTALL_FAILED_INVALID_APK`) and refuses a "signature update" over a
# differently-signed app. Every release APK is therefore signed with the SAME
# stable keystore, provisioned here from the WAQT_* secrets, and in CI the
# keystore is REQUIRED — the build fails rather than ever ship an unsigned or
# debug-signed release. `build.sh --detect-version` and `--release-notes` back
# the thin release.yml workflow (version/notes/commits stay in the workflow).
#
# Works locally and in CI (CI=true). Locally, when no WAQT_* env vars are set
# it reuses an existing android/key.properties if there is one, else it falls
# back to Android's debug key (see android/app/build.gradle.kts) — enough for
# local `flutter run --release` on a fresh clone.
#
# GitHub secrets (also used directly by release.yml):
#   WAQT_KEYSTORE_BASE64   = base64 of the mawaqit-release.jks keystore
#   WAQT_KEYSTORE_PASSWORD = keystore password
#   WAQT_KEY_ALIAS         = signing key alias
#   WAQT_KEY_PASSWORD      = signing key password
#
# Usage:
#   ./build.sh                      provision keystore + build + stage artifacts
#   ./build.sh -v                   verbose (already default; kept for parity)
#   ./build.sh --detect-version     print tag= / version= / versionCode= lines
#                                   (designed to be appended to $GITHUB_OUTPUT)
#   ./build.sh --release-notes      extract this version's CHANGELOG section
#                                   into dist/notes.md
#   ./build.sh --keygen             generate a fresh release keystore and print
#                                   its base64 + passwords (for setup / CI secrets)
#   ./build.sh --no-version-checksum  skip the uncommitted-changes sanity check
#
# Exit codes: 0 = success, 1 = failure (missing deps / secrets / artifacts).

set -euo pipefail

cd "$(dirname "$0")"

# True when running on GitHub Actions / other CI.
CI_RUNNER="${CI:-false}"

# ── Flags ─────────────────────────────────────────────────────────────────────
VERBOSE=false
MODE=build            # build | detect-version | release-notes | keygen
CHECK_VERSION=true
KEYSTORE_NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose) VERBOSE=true ;;
  --detect-version) MODE=detect-version ;;
  --release-notes) MODE=release-notes ;;
  --keygen)
    MODE=keygen
    if [[ $# -gt 1 && "$2" != -* ]]; then
      KEYSTORE_NAME="$2"
      shift
    fi
    ;;
  --no-version-checksum) CHECK_VERSION=false ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# ── Helpers ───────────────────────────────────────────────────────────────────
info() { printf '\033[1;36m[mawaqit]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[mawaqit]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[mawaqit]\033[0m %s\n' "$*" >&2; }

# ── Versioning ────────────────────────────────────────────────────────────────
# `pubspec.yaml` is the single source of truth. The tag is `v<semver>` and the
# versionCode is derived as major*10000 + minor*100 + patch so a small
# semi-ordered number can be used for tags/manifests regardless of `+<build>`.
get_version() { sed -n 's/^version: *//p' pubspec.yaml | head -n1; }

VERSION="$(get_version)"
VERSION="${VERSION%%+*}"          # strip any +<build-number> metadata
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
VERSION_CODE=$(( MAJOR * 10000 + MINOR * 100 + PATCH ))
TAG="v${VERSION}"

# ── Mode: print version lines for $GITHUB_OUTPUT / scripting ──────────────
if [[ "$MODE" == detect-version ]]; then
  printf 'tag=%s\nversion=%s\nversionCode=%s\n' "$TAG" "$VERSION" "$VERSION_CODE"
  exit 0
fi

# ── Mode: extract this release's CHANGELOG section into dist/notes.md ─────────
if [[ "$MODE" == release-notes ]]; then
  mkdir -p dist
  sed -n "/^## \\[$VERSION\\]/,/^## \\[/p" CHANGELOG.md \
    | sed '$d' \
    | sed -E '/^[[:space:]]*\[[^]]+\]:[[:space:]]/d' \
    | sed 's/^[[:space:]]*//' \
    > dist/notes.md
  if [[ ! -s dist/notes.md ]]; then
    err "CHANGELOG.md has no '## [$VERSION]' section — add the release notes first."
    exit 1
  fi
  info "Release notes extracted -> dist/notes.md ($(wc -l < dist/notes.md) lines)"
  exit 0
fi

# ── Mode: generate a fresh keystore for signing ───────────────────────────────
if [[ "$MODE" == keygen ]]; then
  : "${keytool:=$(command -v keytool || echo "${JAVA_HOME:+$JAVA_HOME/bin/}keytool")}"
  STORE="${KEYSTORE_NAME:-mawaqit-release.jks}"
  DIST="dist"
  KEYSTORE_FILE="$DIST/$STORE"
  mkdir -p "$DIST"
  if [[ -f "$KEYSTORE_FILE" ]]; then
    err "$KEYSTORE_FILE already exists — refusing to overwrite. Remove it first if you really want a new key."
    exit 1
  fi
  STORE_PASS="$(openssl rand -hex 12)"
  KEY_PASS="$STORE_PASS"
  ALIAS="mawaqit"
  keytool -genkeypair -v \
    -keystore "$KEYSTORE_FILE" \
    -alias "$ALIAS" \
    -keyalg RSA \
    -keysize 4096 \
    -validity 10000 \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=Mawaqit, OU=Release, O=Mawaqit, L=Rabat, C=MA" >/dev/null
  echo
  info "Keystore written to $KEYSTORE_FILE (KEEP IT SAFE — anyone with it can ship your app)."
  echo "Writes these into android/key.properties locally and these GitHub secrets:"
  echo "  WAQT_KEYSTORE_BASE64   = $(base64 -w0 "$KEYSTORE_FILE")"
  echo "  WAQT_KEYSTORE_PASSWORD = $STORE_PASS"
  echo "  WAQT_KEY_ALIAS         = $ALIAS"
  echo "  WAQT_KEY_PASSWORD      = $KEY_PASS"
  exit 0
fi

# ── Provision the Android release keystore ──────────────────────────────────
# In CI the WAQT_* secrets are REQUIRED (see header). Locally they're optional:
# reuse an existing key.properties or fall back to debug signing.
provision_keystore() {
  if [[ -n "${WAQT_KEYSTORE_BASE64:-}" ]]; then
    local store_password="${WAQT_KEYSTORE_PASSWORD:?WAQT_KEYSTORE_PASSWORD not set}"
    local key_alias="${WAQT_KEY_ALIAS:?WAQT_KEY_ALIAS not set}"
    local key_password="${WAQT_KEY_PASSWORD:?WAQT_KEY_PASSWORD not set}"

    info "Provisioning Android release keystore (alias '$key_alias')..."
    mkdir -p android/app/keystores
    printf '%s' "$WAQT_KEYSTORE_BASE64" | base64 -d > android/app/keystores/mawaqit.jks
    # storeFile is relative to android/app/ (where build.gradle.kts resolves file()).
    cat > android/key.properties <<EOF
storePassword=${store_password}
keyPassword=${key_password}
keyAlias=${key_alias}
storeFile=keystores/mawaqit.jks
EOF
    # Verify the alias up front so a misconfigured secret fails fast.
    keytool -keystore android/app/keystores/mawaqit.jks -list \
      -storepass "${store_password}" -alias "${key_alias}" >/dev/null
    return
  fi

  if [[ "$CI_RUNNER" == true ]]; then
    err "WAQT_KEYSTORE_BASE64 is not set — CI release builds MUST be signed"
    err "with the stable release keystore. Configure the WAQT_* secrets on"
    err "GitHub (see build.sh header / ./build.sh --keygen). Refusing to"
    err "ship an unsigned release."
    exit 1
  fi

  if [[ -f android/key.properties ]]; then
    warn "No WAQT_* secrets in env — reusing android/key.properties."
  else
    warn "No keystore found — building with Android's debug signing (local only)."
  fi
}

# ── Builds ───────────────────────────────────────────────────────────────────
# One slim APK per supported ABI (arm32 / arm64) …
build_split_abis() {
  info "Building split-per-ABI release APKs (arm / arm64)..."
  flutter build apk --release --split-per-abi \
    --target-platform android-arm,android-arm64 \
    -Pforce-version-code-ignoring-abi=true
}

# …and one universal fat APK (arm + arm64) — the artifact every user can
# sideload, and what Release assets point to first.
build_universal() {
  info "Building universal release APK (arm + arm64)..."
  flutter build apk --release \
    --target-platform android-arm,android-arm64
}

# ── Stage + checksum ─────────────────────────────────────────────────────────
stage_artifacts() {
  info "Staging artifacts under dist/ ..."
  mkdir -p dist
  local out="build/app/outputs/flutter-apk"

  for src_name in app-armeabi-v7a-release.apk app-arm64-v8a-release.apk app-release.apk; do
    [[ -f "$out/$src_name" ]] || { err "Missing build output: $out/$src_name"; exit 1; }
  done

  cp "$out/app-armeabi-v7a-release.apk" "dist/mawaqit-v${VERSION}-armeabi-v7a.apk"
  cp "$out/app-arm64-v8a-release.apk"   "dist/mawaqit-v${VERSION}-arm64-v8a.apk"
  cp "$out/app-release.apk"             "dist/mawaqit-v${VERSION}-universal.apk"

  ( cd dist && sha256sum ./*.apk > checksums.txt )
  echo
  info "Staged files:"
  ls -1 dist
}

# ── Signature verification ───────────────────────────────────────────────────
# Belt-and-braces: prove every APK we're about to publish actually verifies,
# using the SDK's apksigner (resolved via android/local.properties).
verify_signing() {
  local sdk_dir apksigner=""
  sdk_dir="$(sed -n 's/^sdk\.dir=//p' android/local.properties 2>/dev/null | head -n1)"
  # Flutter writes android/local.properties during the build, but fall back to
  # the environment (GitHub runners export ANDROID_HOME/ANDROID_SDK_ROOT).
  if [[ -z "$sdk_dir" ]]; then
    sdk_dir="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  fi

  if [[ -n "$sdk_dir" && -d "$sdk_dir/build-tools" ]]; then
    apksigner="$(find "$sdk_dir/build-tools" -name apksigner -type f 2>/dev/null | sort -V | tail -n1 || true)"
  fi
  if [[ -z "$apksigner" ]] && command -v apksigner >/dev/null 2>&1; then
    apksigner="$(command -v apksigner)"
  fi
  if [[ -z "$apksigner" ]]; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "apksigner not found — cannot verify the release signatures in CI."
      exit 1
    fi
    warn "apksigner not found — skipping signature verification."
    return
  fi

  local apk
  for apk in dist/mawaqit-v${VERSION}-*.apk; do
    info "Verifying signature: ${apk##*/}"
    "$apksigner" verify --print-certs "$apk" >/dev/null
  done
  info "All APKs verify — release-signing confirmed."
}

# ── Sanity checks ────────────────────────────────────────────────────────────
check_version_checksum() {
  if [[ "$CHECK_VERSION" == false || "$CI_RUNNER" == true ]]; then
    return
  fi
  if ! [[ "$(git status --porcelain 2>/dev/null)" == "" ]]; then
    warn "Working tree has uncommitted changes; building anyway (dirty build)."
    warn "Pass --no-version-checksum to silence this check."
  fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════"
echo "  mawaqit — release build"
echo "  version: $VERSION   (versionCode $VERSION_CODE, tag $TAG)"
echo "════════════════════════════════════════════"

info "Fetching dependencies..."
flutter pub get

check_version_checksum
provision_keystore
build_split_abis
build_universal
stage_artifacts
verify_signing

echo
info "All release artifacts built, signed and verified."