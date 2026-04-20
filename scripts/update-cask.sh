#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Fetch the DMG for a given version from GitHub Releases, compute its SHA256,
# rewrite homebrew-tap/Casks/spoonlift.rb, and push the update to the tap
# repo so users get it with `brew upgrade --cask spoonlift`.
#
# Usage: scripts/update-cask.sh [version] [--no-push]
# Default version: the newest release tag on GitHub.
# --no-push: update the cask file locally but skip the git commit/push step.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAP_DIR="${ROOT_DIR}/homebrew-tap"
CASK_FILE="${TAP_DIR}/Casks/spoonlift.rb"
REPO="KillianG/Spoonlift"

PUSH=1
VERSION=""
for arg in "$@"; do
    case "$arg" in
        --no-push) PUSH=0 ;;
        -h|--help)
            sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) VERSION="$arg" ;;
    esac
done

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

if [[ "${PUSH}" == "0" ]]; then
    echo "ℹ --no-push: skipping git commit. Push manually when ready."
    exit 0
fi

# The tap directory must be a git repo with its own remote (the
# KillianG/homebrew-tap GitHub repo) — not a subdirectory of this project's git.
if [[ ! -d "${TAP_DIR}/.git" ]]; then
    echo
    echo "ℹ ${TAP_DIR} isn't a git repository yet. Initialise it once with:"
    echo "  cd homebrew-tap"
    echo "  git init && git branch -M main"
    echo "  git add . && git commit -m 'Initial tap: Spoonlift ${VERSION}'"
    echo "  git remote add origin git@github.com:KillianG/homebrew-tap.git"
    echo "  git push -u origin main"
    echo "Then re-run this script to push future updates automatically."
    exit 0
fi

cd "${TAP_DIR}"

if git diff --quiet -- Casks/spoonlift.rb; then
    echo "ℹ No change to Casks/spoonlift.rb — cask already at ${VERSION} with this SHA256."
    exit 0
fi

echo "▸ Committing update to tap repo"
git add Casks/spoonlift.rb
git commit -m "Update Spoonlift to ${VERSION}"

if git remote | grep -q .; then
    echo "▸ Pushing to $(git remote get-url origin 2>/dev/null || echo 'remote')"
    git push
    echo "✓ Cask pushed. Users upgrade with: brew update && brew upgrade --cask spoonlift"
else
    echo "ℹ No git remote configured in the tap repo. Commit made locally; add a remote and push when ready."
fi
