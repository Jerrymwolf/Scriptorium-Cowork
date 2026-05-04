#!/usr/bin/env bash
#
# Release a new version of scriptorium-cowork.
#
# Usage:
#   ./scripts/release.sh 0.1.3
#
# Prerequisites:
#   - You're in the scriptorium-cowork repo root (./scripts/release.sh works)
#   - gh is authenticated (gh auth status)
#   - The version in plugin.json, marketplace.json, and CHANGELOG.md is already bumped to the target
#   - Working tree is clean
#
# What it does:
#   1. Verifies preflight (gh auth, clean tree, version already bumped, release doesn't exist)
#   2. Commits and pushes any pending changes
#   3. Builds the .plugin zip
#   4. Tags and pushes the tag
#   5. Cuts a GitHub release with the version's CHANGELOG section as notes
#   6. Attaches the .plugin file as a release asset
#   7. Prints the share line
#
# Exits non-zero on any failure.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>  (e.g. $0 0.1.3)"
  exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
PLUGIN_FILE="/tmp/scriptorium-cowork.plugin"
NOTES_FILE="/tmp/release-notes-${VERSION}.md"
REPO="Jerrymwolf/Scriptorium-Cowork"

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

echo "=== Preflight ==="

# gh auth
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh not authenticated. Run 'gh auth login' and retry." >&2
  exit 1
fi
echo "  gh: authenticated"

# Working tree
if [ -n "$(git status --porcelain)" ]; then
  echo "  uncommitted changes detected:"
  git status --short
  read -r -p "  Commit them with the release message? [y/N] " yn
  if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
    git add .
    git commit -m "Release v${VERSION}"
  else
    echo "ERROR: working tree must be clean to release." >&2
    exit 1
  fi
fi
echo "  working tree: clean"

# Version in plugin.json
ACTUAL_VERSION="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])")"
if [ "$ACTUAL_VERSION" != "$VERSION" ]; then
  echo "ERROR: plugin.json says version '$ACTUAL_VERSION' but you're releasing '$VERSION'." >&2
  echo "Bump .claude-plugin/plugin.json, .claude-plugin/marketplace.json, and CHANGELOG.md first." >&2
  exit 1
fi
echo "  plugin.json: $ACTUAL_VERSION"

# Full plugin validation
if [ -f scripts/validate-plugin.js ]; then
  node scripts/validate-plugin.js >/tmp/scriptorium-cowork-validate.log
  cat /tmp/scriptorium-cowork-validate.log
else
  echo "ERROR: scripts/validate-plugin.js is missing." >&2
  exit 1
fi

# Release doesn't exist yet
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "ERROR: release $TAG already exists on $REPO." >&2
  exit 1
fi
echo "  release $TAG: doesn't exist yet"

# CHANGELOG has an entry for this version
if ! grep -q "^## ${VERSION}" CHANGELOG.md; then
  echo "ERROR: no '## ${VERSION}' section in CHANGELOG.md." >&2
  exit 1
fi
echo "  CHANGELOG.md: has ## ${VERSION} section"

echo
echo "=== Push pending commits ==="
git push

echo
echo "=== Build .plugin ==="
rm -f "$PLUGIN_FILE"
# Exclusion rationale:
#   *.git*                 — git metadata and .gitignore (not user-facing)
#   *.DS_Store             — macOS folder metadata
#   *.plugin               — prior build artifacts
#   scripts/*              — developer-only release tooling
#   .github/*              — CI workflows
#   .claude-plugin/marketplace.json — marketplace manifest belongs in the GitHub repo
#                            for the /plugin marketplace add path; including it inside
#                            the .plugin file is redundant and historically caused
#                            validator confusion (Cowork treats a package as either
#                            plugin or marketplace, not both)
zip -r "$PLUGIN_FILE" . \
  -x "*.git*" "*.DS_Store" "*.plugin" \
     "scripts/release.sh" "scripts/*" \
     ".github/*" \
     ".claude-plugin/marketplace.json" \
  >/dev/null
SKILL_COUNT="$(unzip -l "$PLUGIN_FILE" | grep -c 'SKILL\.md$' || true)"
SIZE_KB="$(($(stat -f%z "$PLUGIN_FILE" 2>/dev/null || stat -c%s "$PLUGIN_FILE") / 1024))"
echo "  built: $PLUGIN_FILE ($SIZE_KB KB, $SKILL_COUNT SKILL.md files)"

echo
echo "=== Extract CHANGELOG section for release notes ==="
# Pull just this version's section: from "## $VERSION" to the next "## " or EOF
awk -v v="$VERSION" '
  /^## / { if (capture) exit; if ($2 == v) { capture=1; print; next } }
  capture { print }
' CHANGELOG.md > "$NOTES_FILE"
NOTE_LINES="$(wc -l < "$NOTES_FILE" | tr -d ' ')"
echo "  notes: $NOTES_FILE ($NOTE_LINES lines)"

echo
echo "=== Tag and release ==="
git tag -a "$TAG" -m "v${VERSION}"
git push origin "$TAG"
gh release create "$TAG" \
  --title "Scriptorium for Cowork v${VERSION}" \
  --notes-file "$NOTES_FILE" \
  "$PLUGIN_FILE"

echo
echo "=== Verify ==="
gh release view "$TAG" --repo "$REPO" --json assets --jq '.assets[].name' | grep -q "scriptorium-cowork.plugin" && echo "  asset: scriptorium-cowork.plugin attached ✓"

echo
echo "=== Done ==="
echo "  Repo:    https://github.com/${REPO}"
echo "  Release: https://github.com/${REPO}/releases/tag/${TAG}"
echo "  Plugin:  https://github.com/${REPO}/releases/download/${TAG}/scriptorium-cowork.plugin"
echo
echo "  Share:   Scriptorium for Cowork v${VERSION} — drag the .plugin file from the release URL into your Cowork chat and click Accept."
