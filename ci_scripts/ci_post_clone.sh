#!/bin/sh
# ci_post_clone.sh — Xcode Cloud: runs after the repo is cloned
# This script runs BEFORE Xcode Cloud builds your project.
# Use it to install tools and generate the Xcode project.
#
# Xcode Cloud environment variables available here:
#   CI_WORKSPACE         Path to the cloned repo
#   CI_BUILD_NUMBER      Auto-incremented build number
#   CI_BRANCH            Current branch name
#   CI_TAG               Tag name (if triggered by tag push)

set -e

echo "=== ci_post_clone: starting ==="

# ── Install XcodeGen ────────────────────────────────────────────────────────
# Xcode Cloud runners have Homebrew available.

if ! command -v xcodegen &>/dev/null; then
  echo "Installing XcodeGen..."
  brew install xcodegen
fi

echo "XcodeGen version: $(xcodegen --version)"

# ── Install Ruby gems (fastlane) ────────────────────────────────────────────
# Xcode Cloud runners have Ruby available.

if [ -f "$CI_WORKSPACE/Gemfile" ]; then
  echo "Installing Ruby gems..."
  cd "$CI_WORKSPACE"
  gem install bundler --quiet
  bundle install --quiet
fi

# ── Install additional tools ────────────────────────────────────────────────
# Uncomment if your project needs these:

# echo "Installing swiftformat..."
# brew install swiftformat

# echo "Installing imagemagick..."
# brew install imagemagick

# ── Generate Xcode project ──────────────────────────────────────────────────

echo "Generating Xcode project from project.yml..."
cd "$CI_WORKSPACE/App"
xcodegen generate

echo "=== ci_post_clone: done ==="
