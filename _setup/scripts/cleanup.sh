#!/usr/bin/env bash
# cleanup.sh — Remove template scaffolding from the app repo
#
# Run this once you've confirmed the app builds, signs, and ships successfully.
# Safe to run multiple times (idempotent).
#
# What it removes:
#   _setup/          — setup guides, scripts, and lessons (template scaffolding)
#   CLAUDE.md        — agent instructions scoped to template setup
#
# What it rewrites:
#   README.md        — strips the template description; leaves a minimal stub
#                      for you to fill in with your app's own description

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DISPLAY_NAME="$(grep -m1 'PRODUCT_NAME' "$REPO_ROOT/App/project.yml" 2>/dev/null | sed 's/.*PRODUCT_NAME: *//' | tr -d '"' || echo 'My App')"

echo "Cleaning up template scaffolding in: $REPO_ROOT"
echo "App display name detected: $APP_DISPLAY_NAME"
echo ""

# --- Remove _setup/ ---
if [ -d "$REPO_ROOT/_setup" ]; then
  rm -rf "$REPO_ROOT/_setup"
  echo "  Removed: _setup/"
else
  echo "  Already removed: _setup/"
fi

# --- Remove root CLAUDE.md (template agent instructions) ---
if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
  rm "$REPO_ROOT/CLAUDE.md"
  echo "  Removed: CLAUDE.md"
else
  echo "  Already removed: CLAUDE.md"
fi

# --- Replace README.md with a minimal app stub ---
cat > "$REPO_ROOT/README.md" << README
# $APP_DISPLAY_NAME

<!-- TODO: Add a one-line description of your app -->

## Building

Requires Xcode 16+ and the dependencies installed via Homebrew:

\`\`\`bash
brew install xcodegen swiftformat swiftlint
cd App && xcodegen generate
\`\`\`

Open \`App/$APP_DISPLAY_NAME.xcodeproj\` in Xcode and run (⌘R).

## Releasing

\`\`\`bash
bundle exec fastlane beta     # Upload to TestFlight
bundle exec fastlane release  # Submit to App Store
\`\`\`
README
echo "  Rewrote: README.md"

echo ""
echo "Done. Commit the result:"
echo "  git add -A && git commit -m 'Remove template scaffolding'"
