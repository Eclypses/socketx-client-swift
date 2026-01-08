#!/bin/bash

# Usage: ./release.sh 2.0.0

# --- CONFIGURATION ---
REPO_URL="https://github.com/Eclypses/socketx-client-swift"
SETTINGS_PATH="SocketXClient/Settings.swift"
CHANGELOG_PATH="CHANGELOG.md"
PACKAGE_PATH="Package.swift"
# ---------------------

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
echo "   git push origin develop && git push origin $TAG_VERSION"
