#!/bin/sh
# ci_pre_xcodebuild.sh — Xcode Cloud: runs just before xcodebuild
# Use it to set build numbers, inject environment-specific config, or validate state.
#
# Xcode Cloud environment variables available here:
#   CI_BUILD_NUMBER           Auto-incremented integer build number
#   CI_PRODUCT                Product name
#   CI_BUNDLE_ID              Bundle identifier
#   CI_BRANCH                 Current branch
#   CI_TAG                    Tag name (if triggered by tag push)
#   CI_XCODEBUILD_ACTION      The action (build, test, archive)

set -e

echo "=== ci_pre_xcodebuild: starting ==="
echo "Action: $CI_XCODEBUILD_ACTION"
echo "Build number: $CI_BUILD_NUMBER"
echo "Product: $CI_PRODUCT"
echo "Bundle ID: $CI_BUNDLE_ID"

# ── Set build number from Xcode Cloud's auto-incremented counter ─────────────

PLIST="$CI_WORKSPACE/App/Sources/__APP_NAME__/Resources/Info.plist"

if [ -f "$PLIST" ] && [ -n "$CI_BUILD_NUMBER" ]; then
  echo "Setting CFBundleVersion to $CI_BUILD_NUMBER in Info.plist..."
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$PLIST"
fi

# ── SwiftFormat (optional) ────────────────────────────────────────────────────
# Uncomment to enforce formatting in CI. Note: this will fail the build if
# any file needs reformatting. Better used as a PR check, not on main.

# if command -v swiftformat &>/dev/null; then
#   echo "Running swiftformat..."
#   swiftformat --lint "$CI_WORKSPACE/App/Sources" \
#     || { echo "SwiftFormat found formatting issues. Run 'swiftformat App/Sources' locally."; exit 1; }
# fi

# ── SwiftLint (optional) ──────────────────────────────────────────────────────
# Uncomment to run linting.

# if command -v swiftlint &>/dev/null; then
#   echo "Running swiftlint..."
#   swiftlint --strict "$CI_WORKSPACE/App/Sources"
# fi

echo "=== ci_pre_xcodebuild: done ==="
