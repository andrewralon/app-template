#!/bin/sh
# ci_post_xcodebuild.sh — Xcode Cloud: runs after xcodebuild completes
# This script runs regardless of whether the build succeeded or failed.
#
# Xcode Cloud environment variables:
#   CI_XCODEBUILD_EXIT_CODE    0 = success, non-zero = failure
#   CI_XCODEBUILD_ACTION       The action that just ran
#   CI_ARCHIVE_PATH            Path to .xcarchive (only set when action = archive)
#   CI_BUILD_NUMBER            Build number

set -e

echo "=== ci_post_xcodebuild: starting ==="
echo "Exit code: $CI_XCODEBUILD_EXIT_CODE"
echo "Action: $CI_XCODEBUILD_ACTION"

# ── React to build outcome ────────────────────────────────────────────────────

if [ "$CI_XCODEBUILD_EXIT_CODE" -eq 0 ]; then
  echo "Build succeeded."

  # Post-archive actions (only runs when Xcode Cloud archives for distribution)
  if [ "$CI_XCODEBUILD_ACTION" = "archive" ] && [ -n "$CI_ARCHIVE_PATH" ]; then
    echo "Archive created at: $CI_ARCHIVE_PATH"
    # Example: export dSYMs for a crash reporting service
    # find "$CI_ARCHIVE_PATH/dSYMs" -name "*.dSYM" -exec cp -r {} /tmp/dsyms/ \;
  fi
else
  echo "Build FAILED with exit code $CI_XCODEBUILD_EXIT_CODE."
  # Example: send a notification (webhook, Slack, etc.)
  # curl -s -X POST "$SLACK_WEBHOOK_URL" \
  #   -H "Content-Type: application/json" \
  #   -d "{\"text\":\"❌ Xcode Cloud build failed (action: $CI_XCODEBUILD_ACTION, build: $CI_BUILD_NUMBER)\"}"
fi

echo "=== ci_post_xcodebuild: done ==="
