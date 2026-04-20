#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Build Spoonlift.app in Release config and package it as a DMG.
# Usage: scripts/build-release.sh [version]
# Default version: 0.1.0

set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="Spoonlift"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "▸ Regenerating Xcode project"
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen not installed. Install with: brew install xcodegen" >&2
    exit 1
fi
xcodegen

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "▸ Building ${APP_NAME} (Release)"
xcodebuild \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    MARKETING_VERSION="${VERSION}" \
    clean build

APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
    echo "✗ Build output not found at ${APP_PATH}" >&2
    exit 1
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

echo "✓ ${BUILD_DIR}/${DMG_NAME}"
