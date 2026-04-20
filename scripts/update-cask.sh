#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Fetch the DMG for a given version from GitHub Releases, compute its SHA256,
# and rewrite homebrew/spoonlift.rb so it's ready to be copied into a
# homebrew-cask PR.
#
# Usage: scripts/update-cask.sh [version]
# Default version: the newest release tag on GitHub.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASK_FILE="${ROOT_DIR}/homebrew/spoonlift.rb"
REPO="KillianG/open-forklift"

VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
    if ! command -v gh >/dev/null; then
        echo "No version given and gh not installed. Either run:" >&2
        echo "  scripts/update-cask.sh 0.1.0" >&2
        echo "or install gh (brew install gh) and let it resolve the latest tag." >&2
        exit 1
    fi
    VERSION=$(gh release view --repo "${REPO}" --json tagName -q .tagName | sed 's/^v//')
    echo "▸ Resolved latest release: v${VERSION}"
fi

DMG_URL="https://github.com/${REPO}/releases/download/v${VERSION}/Spoonlift-${VERSION}.dmg"

echo "▸ Downloading ${DMG_URL}"
TMP_DMG="$(mktemp -t spoonlift).dmg"
trap 'rm -f "${TMP_DMG}"' EXIT
curl -fL --progress-bar -o "${TMP_DMG}" "${DMG_URL}"

SHA256=$(shasum -a 256 "${TMP_DMG}" | awk '{print $1}')
echo "▸ SHA256: ${SHA256}"

# Rewrite version + sha256 in the cask file
/usr/bin/sed -i '' -E "s|^(  version \")[^\"]+(\")|\1${VERSION}\2|" "${CASK_FILE}"
/usr/bin/sed -i '' -E "s|^(  sha256 \")[^\"]+(\")|\1${SHA256}\2|" "${CASK_FILE}"

echo "✓ Updated ${CASK_FILE}"
echo
echo "Next steps to push this to homebrew-cask:"
echo "  1. Fork https://github.com/Homebrew/homebrew-cask"
echo "  2. git clone your fork, cd into it, branch off main"
echo "  3. cp ${CASK_FILE} Casks/s/spoonlift.rb"
echo "  4. brew style --fix Casks/s/spoonlift.rb"
echo "  5. brew audit --new-cask spoonlift"
echo "  6. git commit -m 'Add spoonlift v${VERSION}' && git push"
echo "  7. Open a PR to Homebrew/homebrew-cask"
