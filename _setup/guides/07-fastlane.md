# 07 — Fastlane

fastlane automates the most painful parts of iOS development: certificates, screenshots, and App Store uploads. It's the difference between a 2-hour manual deploy and a one-line command.

---

## Installation

```bash
# fastlane is a Ruby gem; use Bundler to pin the version
bundle install  # reads Gemfile in the project root
```

The template includes a `Gemfile` and `Gemfile.lock` so everyone uses the same version.

```bash
# All fastlane commands go through Bundler:
bundle exec fastlane <lane_name>
```

---

## File Overview

```
fastlane/
├── Fastfile      ← Lane definitions (automation scripts)
├── Appfile       ← App identifiers (bundle ID, Apple ID)
├── Matchfile     ← Code signing configuration
└── Deliverfile   ← App Store metadata configuration
```

---

## Appfile

```ruby
app_identifier "__BUNDLE_ID__"
apple_id ENV.fetch("APPLE_ID", "")    # set in fastlane/.env
team_id ENV.fetch("APPLE_TEAM_ID", "")
```

`__BUNDLE_ID__` is replaced by `init.sh`. `APPLE_ID` and `APPLE_TEAM_ID` come from `fastlane/.env` (gitignored) or CI environment variables — never committed to the repo.

---

## fastlane match — Code Signing

`match` creates and stores all certificates and profiles in a private git repository. Every machine (and CI) clones that repo to get the certs. No more "signing certificate not found" misery.

### Initialize match (first time only)

```bash
bundle exec fastlane match init
```

When prompted:
- Storage mode: `git`
- Git URL: your SSH certs repo URL (e.g. `git@github.com:yourorg/app-certs.git`)

This creates `fastlane/Matchfile`. The `init.sh` wizard handles this automatically and pre-fills `MATCH_GIT_URL` in `fastlane/.env`.

### Create Certificates

```bash
# Development (for local device builds)
bundle exec fastlane match development

# App Store distribution (for TestFlight and App Store)
bundle exec fastlane match appstore

# Ad Hoc (for direct device distribution without TestFlight)
bundle exec fastlane match adhoc
```

Each command:
1. Clones the match repo
2. Checks if a valid cert already exists
3. Creates a new one if needed
4. Stores it in the repo and your Keychain

### Use Existing Certificates (read-only)

On CI or other team members' machines:
```bash
bundle exec fastlane match development --readonly
bundle exec fastlane match appstore --readonly
```

### Rotate Compromised Certificates

```bash
# Revoke and recreate all certificates
bundle exec fastlane match nuke development
bundle exec fastlane match nuke distribution
bundle exec fastlane match development
bundle exec fastlane match appstore
```

### Matchfile

```ruby
git_url ENV.fetch("MATCH_GIT_URL", "")  # set in fastlane/.env or CI secrets
storage_mode "git"
app_identifier ["__BUNDLE_ID__"]
username ENV.fetch("APPLE_ID", "")
team_id ENV.fetch("APPLE_TEAM_ID", "")
readonly(is_ci)
```

`MATCH_GIT_URL`, `APPLE_ID`, and `APPLE_TEAM_ID` are read from environment variables — not committed to the repo. Set them in `fastlane/.env` locally and as GitHub Actions secrets in CI.

---

## Fastfile Lanes

### test — Run Tests

```bash
bundle exec fastlane test
```

Runs all unit and UI tests. Used in CI on every PR.

### beta — Build and Upload to TestFlight

```bash
bundle exec fastlane beta
```

What it does:
1. Increments the build number
2. Syncs code signing (match appstore --readonly)
3. Builds the archive
4. Uploads to TestFlight via App Store Connect API

### release — Submit to App Store

```bash
bundle exec fastlane release
```

What it does:
1. Runs tests (fail fast before wasting time on a broken build)
2. Increments build number
3. Builds the archive
4. Uploads to App Store Connect
5. Submits for review (optional — you can skip this and submit manually)

### screenshots — Generate App Store Screenshots

```bash
bundle exec fastlane screenshots
```

Uses `snapshot` to launch the app in various simulators and take screenshots, then `frameit` to apply device frames.

---

## Fastfile Reference

```ruby
# fastlane/Fastfile

default_platform(:ios)

platform :ios do

  before_all do
    ensure_git_status_clean  # fail if uncommitted changes
  end

  desc "Run tests"
  lane :test do
    run_tests(
      project: "App/__APP_NAME__.xcodeproj",
      scheme: "__APP_NAME__",
      devices: ["iPhone 16 Pro"],
      clean: true,
      result_bundle: true,
      output_directory: "fastlane/test_output"
    )
  end

  desc "Sync code signing (development)"
  lane :sync_dev_signing do
    match(type: "development", readonly: is_ci)
  end

  desc "Sync code signing (App Store)"
  lane :sync_release_signing do
    match(type: "appstore", readonly: is_ci)
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    sync_release_signing

    increment_build_number(
      xcodeproj: "App/__APP_NAME__.xcodeproj"
    )

    build_app(
      project: "App/__APP_NAME__.xcodeproj",
      scheme: "__APP_NAME__",
      configuration: "Release",
      output_directory: "build",
      export_method: "app-store"
    )

    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      api_key: app_store_connect_api_key
    )

    clean_build_artifacts
  end

  desc "Submit to App Store"
  lane :release do
    test

    sync_release_signing

    increment_build_number(
      xcodeproj: "App/__APP_NAME__.xcodeproj"
    )

    build_app(
      project: "App/__APP_NAME__.xcodeproj",
      scheme: "__APP_NAME__",
      configuration: "Release",
      output_directory: "build",
      export_method: "app-store"
    )

    upload_to_app_store(
      api_key: app_store_connect_api_key,
      submit_for_review: true,
      automatic_release: false,
      force: true,
      skip_screenshots: false,
      skip_metadata: false
    )

    clean_build_artifacts
  end

  desc "Generate App Store screenshots"
  lane :screenshots do
    capture_screenshots(
      project: "App/__APP_NAME__.xcodeproj",
      scheme: "__APP_NAME__UITests",
      devices: [
        "iPhone 16 Pro Max",
        "iPhone 15 Plus",
        "iPad Pro (12.9-inch) (6th generation)"
      ],
      languages: ["en-US"],
      output_directory: "fastlane/screenshots",
      clear_previous_screenshots: true
    )

    frame_screenshots(
      white: true,
      path: "fastlane/screenshots"
    )
  end

  desc "Download dSYMs for crash symbolication"
  lane :download_dsyms do
    download_dsyms(
      api_key: app_store_connect_api_key,
      app_identifier: "__BUNDLE_ID__",
      version: "latest"
    )
  end

  private_lane :app_store_connect_api_key do
    key_id    = ENV.fetch("APP_STORE_CONNECT_API_KEY_ID")
    issuer_id = ENV.fetch("APP_STORE_CONNECT_API_KEY_ISSUER_ID")
    if ENV["APP_STORE_CONNECT_API_KEY_PATH"] && File.exist?(ENV["APP_STORE_CONNECT_API_KEY_PATH"])
      # Local: read from .p8 file on disk
      app_store_connect_api_key(key_id: key_id, issuer_id: issuer_id,
        key_filepath: ENV.fetch("APP_STORE_CONNECT_API_KEY_PATH"),
        is_key_content_base64: false)
    else
      # CI: read from base64-encoded secret
      app_store_connect_api_key(key_id: key_id, issuer_id: issuer_id,
        key_content: ENV.fetch("APP_STORE_CONNECT_API_KEY_CONTENT"),
        is_key_content_base64: true)
    end
  end

  error do |lane, exception|
    # Notify on failure (e.g., Slack)
    # slack(message: "Lane #{lane} failed: #{exception.message}", success: false)
  end

end
```

---

## Environment Variables

Never hardcode credentials in the Fastfile. Set them as environment variables:

```bash
# In your shell or CI environment:
export MATCH_PASSWORD="your_match_passphrase"
export APP_STORE_CONNECT_API_KEY_ID="ABCD123456"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export APP_STORE_CONNECT_API_KEY_CONTENT="LS0tLS1CRUdJTi4uLg=="  # base64-encoded .p8
```

For local development, use a `.env` file in the `fastlane/` directory (gitignored):

```bash
# fastlane/.env
MATCH_PASSWORD=your_match_passphrase
APP_STORE_CONNECT_API_KEY_ID=ABCD123456
APP_STORE_CONNECT_API_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_CONNECT_API_KEY_CONTENT=LS0tLS1CRUdJTi4uLg==
```

fastlane automatically loads `fastlane/.env`. Do not commit this file.

---

## App Store Connect API Key Setup

The API key lets fastlane authenticate without a password or 2FA:

```bash
# 1. Generate the key in App Store Connect:
#    Users and Access → Integrations → App Store Connect API → Generate API Key
#    Role: App Manager
#    Download the .p8 file (one-time download!)

# 2. Encode the key file:
cat ~/Downloads/AuthKey_ABCD123456.p8 | base64 | pbcopy
# (this copies the base64 string to your clipboard)

# 3. Set environment variables:
export APP_STORE_CONNECT_API_KEY_ID="ABCD123456"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export APP_STORE_CONNECT_API_KEY_CONTENT="<paste base64 here>"
```

---

## Incrementing Build Numbers

fastlane can automatically increment the build number. Two strategies:

### From Last Upload

```ruby
increment_build_number(
  xcodeproj: "App/__APP_NAME__.xcodeproj"
  # reads current build number from Xcode and increments it
)
```

### From App Store Connect (safe for CI)

```ruby
latest_build_number = latest_testflight_build_number(
  api_key: app_store_connect_api_key,
  app_identifier: "__BUNDLE_ID__"
)
increment_build_number(
  build_number: latest_build_number + 1,
  xcodeproj: "App/__APP_NAME__.xcodeproj"
)
```

This is CI-safe because it reads the actual last uploaded number, avoiding conflicts.

---

## Common Issues

### "Certificate is not available in your portal"

```bash
bundle exec fastlane match development --force
```

### "No provisioning profiles found"

```bash
bundle exec fastlane match appstore --force_for_new_devices
```

### "Build number already exists"

Increment `CURRENT_PROJECT_VERSION` in `project.yml` and regenerate.

### Two-factor authentication blocking CI

Use an App Store Connect API key instead of Apple ID + password. API keys bypass 2FA.

### "match passphrase incorrect"

The `MATCH_PASSWORD` environment variable must match the passphrase used when `match init` was run. Check it in your `.env` file or CI secrets.
