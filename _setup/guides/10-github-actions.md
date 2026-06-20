# 10 — GitHub Actions CI/CD

Automate your build, test, and release pipeline so every push is verified and every release is one git tag away.

---

## Overview

Two workflows are included:

| File | Trigger | Purpose |
|---|---|---|
| `.github/workflows/ci.yml` | Push to any branch, PRs to main | Build + run tests |
| `.github/workflows/release.yml` | Push a `v*` tag | Build + upload to TestFlight |

---

## Required GitHub Secrets

Set these in GitHub → your repo → Settings → Secrets and Variables → Actions:

| Secret Name | Value |
|---|---|
| `MATCH_PASSWORD` | Passphrase for fastlane match git repo |
| `MATCH_GIT_URL` | SSH URL of the private match certs repo (e.g. `git@github.com:org/certs.git`) |
| `MATCH_GIT_PRIVATE_KEY` | SSH private key with access to the match certs repo |
| `APPLE_ID` | Apple ID email for App Store Connect (e.g. `dev@example.com`) |
| `APPLE_TEAM_ID` | 10-char Apple Developer Team ID (e.g. `ABCD123456`) |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from App Store Connect API |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID from App Store Connect API |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded contents of the `.p8` key file |
| `KEYCHAIN_PASSWORD` | Any random strong password (used to create a temp keychain on CI) |

### Generating the SSH Key for match

```bash
# Generate a deploy key
ssh-keygen -t ed25519 -f ~/.ssh/match_deploy_key -N "" -C "ci-match"

# Add the public key as a Deploy Key to the match certs repo:
# certs repo → Settings → Deploy Keys → Add key (read/write)
cat ~/.ssh/match_deploy_key.pub

# Add the private key as a GitHub secret:
cat ~/.ssh/match_deploy_key
# Copy and paste into MATCH_GIT_PRIVATE_KEY
```

### Encoding the API Key

```bash
cat ~/Downloads/AuthKey_KEYID.p8 | base64 | tr -d '\n'
# Paste the output into APP_STORE_CONNECT_API_KEY_CONTENT
```

---

## ci.yml — Continuous Integration

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches:
      - main
      - 'feature/**'
  pull_request:
    branches:
      - main

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    name: Build & Test
    runs-on: macos-15

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.3.app

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true  # caches gems based on Gemfile.lock

      - name: Install SSH key for match
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.MATCH_GIT_PRIVATE_KEY }}

      - name: Cache derived data
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-derived-${{ hashFiles('App/project.yml') }}
          restore-keys: |
            ${{ runner.os }}-derived-

      - name: Generate Xcode project
        run: |
          cd App
          brew install xcodegen || true
          xcodegen generate

      - name: Sync development signing
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: bundle exec fastlane sync_dev_signing

      - name: Run tests
        run: bundle exec fastlane test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: fastlane/test_output/
          retention-days: 30
```

---

## release.yml — TestFlight Release

```yaml
# .github/workflows/release.yml
name: Release to TestFlight

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'  # matches v1.2.3

jobs:
  release:
    name: Build & Upload to TestFlight
    runs-on: macos-15

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # needed for build number from git history

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.3.app

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install SSH key for match
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.MATCH_GIT_PRIVATE_KEY }}

      - name: Generate Xcode project
        run: |
          cd App
          brew install xcodegen || true
          xcodegen generate

      - name: Create temporary keychain
        run: |
          security create-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
          security set-keychain-settings -t 3600 -u build.keychain

      - name: Set App Store Connect API key
        run: |
          echo "${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}" | base64 --decode > /tmp/api_key.p8

      - name: Build and upload to TestFlight
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: bundle exec fastlane beta

      - name: Delete temporary keychain
        if: always()
        run: security delete-keychain build.keychain

      - name: Upload build artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ github.ref_name }}
          path: build/
          retention-days: 14
```

---

## Releasing a New Version

With this setup, releasing is a single command:

```bash
# 1. Bump version in App/project.yml
# MARKETING_VERSION: 1.2.0

# 2. Commit
git add App/project.yml
git commit -m "chore: bump version to 1.2.0"

# 3. Tag and push
git tag v1.2.0
git push && git push --tags
```

The `release.yml` workflow fires, builds, and uploads to TestFlight automatically.

---

## macOS Runners and Xcode Versions

GitHub's hosted macOS runners:

| Runner | macOS | Xcode versions available |
|---|---|---|
| `macos-15` | Sequoia | Xcode 16.x (latest recommended) |
| `macos-14` | Sonoma | Xcode 15.x, 16.x |
| `macos-13` | Ventura | Xcode 14.x, 15.x |

Check available Xcode versions: [github.com/actions/runner-images](https://github.com/actions/runner-images)

Select Xcode explicitly in your workflow to avoid surprises when the runner image updates:
```bash
sudo xcode-select -s /Applications/Xcode_16.3.app
```

---

## Caching for Faster Builds

Cache everything that takes time to install or build:

```yaml
# Cache Ruby gems
- uses: ruby/setup-ruby@v1
  with:
    bundler-cache: true  # handles gem caching automatically

# Cache Xcode derived data
- uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: derived-${{ hashFiles('App/project.yml', 'App/**/*.swift') }}

# Cache Homebrew packages
- uses: actions/cache@v4
  with:
    path: ~/Library/Caches/Homebrew
    key: homebrew-${{ hashFiles('.github/workflows/ci.yml') }}
```

---

## Branch Protection Rules

Protect your `main` branch to enforce CI:

1. GitHub → repo → Settings → Branches → Add branch protection rule
2. Branch name pattern: `main`
3. Enable:
   - Require a pull request before merging
   - Require status checks to pass (select your CI job name)
   - Require branches to be up to date before merging
   - Restrict who can push to matching branches

---

## Notifications

Add Slack or email notifications for build failures:

```yaml
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    fields: repo,message,commit,author
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

Or use GitHub's built-in email notifications (Settings → Notifications).
