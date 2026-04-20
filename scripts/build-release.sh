#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Build Spoonlift.app in Release config, package it as a DMG, and (if the
# right env vars are set) sign + notarize with a Developer ID.
#
# Usage: scripts/build-release.sh [version]
#
# Environment variables (all optional; if any are missing we fall back to an
# ad-hoc build that skips notarization):
#   APPLE_SIGNING_IDENTITY   full "Developer ID Application: Name (TEAMID)" string
#   APPLE_ID                 Apple ID email used for notarization
#   APPLE_TEAM_ID            10-char Team ID
#   APPLE_APP_PASSWORD       app-specific password from appleid.apple.com

set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="Spoonlift"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

SIGN_IDENTITY="${APPLE_SIGNING_IDENTITY:-}"
DO_SIGN=0
DO_NOTARIZE=0
if [[ -n "${SIGN_IDENTITY}" ]]; then
    DO_SIGN=1
    if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
        DO_NOTARIZE=1
    fi
fi

echo "▸ Regenerating Xcode project"
command -v xcodegen >/dev/null || { echo "install xcodegen first (brew install xcodegen)" >&2; exit 1; }
xcodegen

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "▸ Building ${APP_NAME} ${VERSION} (signed=${DO_SIGN}, notarize=${DO_NOTARIZE})"

if [[ "${DO_SIGN}" == "1" ]]; then
    xcodebuild \
        -project "${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        CODE_SIGN_STYLE=Manual \
        CODE_SIGN_IDENTITY="${SIGN_IDENTITY}" \
        DEVELOPMENT_TEAM="${APPLE_TEAM_ID}" \
        OTHER_CODE_SIGN_FLAGS="--timestamp" \
        MARKETING_VERSION="${VERSION}" \
        clean build
else
    xcodebuild \
        -project "${APP_NAME}.xcodeproj" \
        -scheme "${APP_NAME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGN_IDENTITY="" \
        MARKETING_VERSION="${VERSION}" \
        clean build
fi

APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"
[[ -d "${APP_PATH}" ]] || { echo "✗ Build output missing: ${APP_PATH}" >&2; exit 1; }

if [[ "${DO_SIGN}" == "1" ]]; then
    echo "▸ Re-signing with hardened runtime"
    codesign --force --deep --options runtime --timestamp \
        --entitlements "Spoonlift/Spoonlift.entitlements" \
        --sign "${SIGN_IDENTITY}" \
        "${APP_PATH}"
    codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
else
    # Strip any residual ad-hoc signature Xcode may have attached, so end
    # users get "unidentified developer" (with a right-click → Open bypass)
    # rather than the "damaged, move to trash" dialog.
    echo "▸ Stripping residual signatures (unsigned build)"
    codesign --remove-signature "${APP_PATH}" 2>/dev/null || true
fi

if [[ "${DO_NOTARIZE}" == "1" ]]; then
    echo "▸ Notarizing the app (round 1 of 2, takes a few minutes)"
    APP_ZIP="${BUILD_DIR}/${APP_NAME}.zip"
    /usr/bin/ditto -c -k --keepParent "${APP_PATH}" "${APP_ZIP}"
    xcrun notarytool submit "${APP_ZIP}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${APPLE_TEAM_ID}" \
        --password "${APPLE_APP_PASSWORD}" \
        --wait
    rm -f "${APP_ZIP}"
    xcrun stapler staple "${APP_PATH}"
fi

echo "▸ Staging DMG contents"
STAGING="${BUILD_DIR}/dmg-staging"
rm -rf "${STAGING}"
mkdir -p "${STAGING}"
cp -R "${APP_PATH}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

echo "▸ Creating ${DMG_NAME}"
rm -f "${BUILD_DIR}/${DMG_NAME}"
hdiutil create \
    -volname "${APP_NAME} ${VERSION}" \
    -srcfolder "${STAGING}" \
    -ov -format UDZO \
    "${BUILD_DIR}/${DMG_NAME}" >/dev/null
rm -rf "${STAGING}"

if [[ "${DO_SIGN}" == "1" ]]; then
    echo "▸ Signing DMG"
    codesign --force --sign "${SIGN_IDENTITY}" --timestamp "${BUILD_DIR}/${DMG_NAME}"
fi

if [[ "${DO_NOTARIZE}" == "1" ]]; then
    echo "▸ Notarizing the DMG (round 2 of 2)"
    xcrun notarytool submit "${BUILD_DIR}/${DMG_NAME}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${APPLE_TEAM_ID}" \
        --password "${APPLE_APP_PASSWORD}" \
        --wait
    xcrun stapler staple "${BUILD_DIR}/${DMG_NAME}"
fi

echo "✓ ${BUILD_DIR}/${DMG_NAME}"
[[ "${DO_NOTARIZE}" == "1" ]] && echo "  (signed + notarized + stapled — launches cleanly on any Mac)"
