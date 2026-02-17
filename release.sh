#!/bin/bash

set -euo pipefail

# Usage: ./release.sh 2.0.0

# --- CONFIGURATION ---
REPO_URL="https://github.com/Eclypses/socketx-client-swift"
SETTINGS_PATH="SocketXClient/Settings.swift"
CHANGELOG_PATH="CHANGELOG.md"
PACKAGE_PATH="Package.swift"
# ---------------------

TARGET_BRANCH="develop"

# 0. Git preflight checks
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
  echo "Error: release must be run from '$TARGET_BRANCH' (current: '$CURRENT_BRANCH')."
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: working tree is not clean. Commit/stash changes before running release.sh."
  exit 1
fi

git fetch origin "$TARGET_BRANCH" --prune

LOCAL_SHA=$(git rev-parse HEAD)
REMOTE_SHA=$(git rev-parse "origin/$TARGET_BRANCH")
BASE_SHA=$(git merge-base HEAD "origin/$TARGET_BRANCH")

if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
  if [ "$LOCAL_SHA" = "$BASE_SHA" ]; then
    echo "Error: local '$TARGET_BRANCH' is behind origin/$TARGET_BRANCH. Run: git pull --rebase origin $TARGET_BRANCH"
  elif [ "$REMOTE_SHA" = "$BASE_SHA" ]; then
    echo "Error: local '$TARGET_BRANCH' is ahead of origin/$TARGET_BRANCH. Push/reconcile first, then rerun release."
  else
    echo "Error: local '$TARGET_BRANCH' and origin/$TARGET_BRANCH have diverged. Reconcile history before releasing."
  fi
  exit 1
fi

# 1. Validation
if [ -z "$1" ]; then
  echo "Error: No version supplied."
  echo "Usage: ./release.sh <new_version>"
  echo "Example: ./release.sh 2.0.0"
  exit 1
fi

# STRIP 'v' if the user accidentally typed it (e.g. v2.0.0 -> 2.0.0)
CLEAN_VERSION="${1#v}"
TAG_VERSION="v$CLEAN_VERSION"
DATE=$(date +%Y-%m-%d)

if git rev-parse -q --verify "refs/tags/$TAG_VERSION" >/dev/null; then
  echo "Error: tag '$TAG_VERSION' already exists locally."
  exit 1
fi

if git ls-remote --tags origin | grep -q "refs/tags/$TAG_VERSION$"; then
  echo "Error: tag '$TAG_VERSION' already exists on origin."
  exit 1
fi

echo "🚀 Preparing release: $TAG_VERSION on $DATE"

# 2. Update Settings.swift (Use CLEAN version: "2.0.0")
# Looks for: static let socketXClientVersion = "..."
sed -i '' "s/static let socketXClientVersion = \".*\"/static let socketXClientVersion = \"$CLEAN_VERSION\"/" "$SETTINGS_PATH"

# 3. Update Package.swift Comment (Use CLEAN version: "2.0.0")
# Looks for: // Version: ...
sed -i '' "s/\/\/ Version: .*/\/\/ Version: $CLEAN_VERSION/" "$PACKAGE_PATH"

# 4. Update CHANGELOG.md Headers
# Uses tags like [2.0.0] for headers
# NOTE: Requires a '## [Unreleased]' section in your CHANGELOG.md to work.
SEARCH="## \[Unreleased\]"
REPLACE="## [Unreleased]\\
\\
### Added\\
-\\
\\
### Changed\\
-\\
\\
### Fixed\\
-\\
\\
\\
## [$CLEAN_VERSION] - $DATE"

sed -i '' "s/$SEARCH/$REPLACE/" "$CHANGELOG_PATH"

# 5. Update CHANGELOG.md Reference Links
# IMPORTANT: The URL must match the Git Tag (which now has 'v')
# Link format: [2.0.0]: .../releases/tag/v2.0.0
NEW_LINK="[$CLEAN_VERSION]: $REPO_URL/releases/tag/$TAG_VERSION"

echo "" >> "$CHANGELOG_PATH"
echo "$NEW_LINK" >> "$CHANGELOG_PATH"

# 6. Git Operations
echo "📦 Committing changes..."
git add "$SETTINGS_PATH" "$PACKAGE_PATH" "$CHANGELOG_PATH"
# Commit message usually uses the clean version or the tag, preference varies.
git commit -m "chore: bump version to $CLEAN_VERSION"

echo "🏷️  Tagging version $TAG_VERSION..."
git tag -a "$TAG_VERSION" -m "Release version $CLEAN_VERSION"

echo "✅ Done! Validate the changes, then run:"
echo "   git push origin develop $TAG_VERSION"
