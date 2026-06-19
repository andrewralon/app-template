# fastlane

fastlane automates building, testing, and releasing your app.

## Setup

```bash
bundle install
```

Set environment variables (or create `fastlane/.env`):

```bash
MATCH_PASSWORD=your_match_passphrase
APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_API_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_CONNECT_API_KEY_CONTENT=LS0tLS1CRUdJTi4uLg==  # base64 .p8 contents
```

## Available Lanes

| Lane | Command | Description |
|---|---|---|
| `test` | `bundle exec fastlane test` | Run all unit and UI tests |
| `sync_dev_signing` | `bundle exec fastlane sync_dev_signing` | Pull development certs via match |
| `sync_release_signing` | `bundle exec fastlane sync_release_signing` | Pull App Store certs via match |
| `beta` | `bundle exec fastlane beta` | Build + upload to TestFlight |
| `release` | `bundle exec fastlane release` | Build + submit to App Store |
| `screenshots` | `bundle exec fastlane screenshots` | Generate App Store screenshots |
| `upload_screenshots` | `bundle exec fastlane upload_screenshots` | Upload screenshots to App Store Connect |
| `download_dsyms` | `bundle exec fastlane download_dsyms` | Download dSYMs for crash symbolication |
| `rotate_certs` | `bundle exec fastlane rotate_certs` | Revoke and recreate all certificates |

## Files

| File | Purpose |
|---|---|
| `Fastfile` | Lane definitions |
| `Appfile` | Default app identifier and Apple ID |
| `Matchfile` | Code signing configuration |
| `Deliverfile` | App Store submission defaults |
| `.env` | Local secrets (gitignored) |

## Code Signing (match)

First-time setup:
```bash
bundle exec fastlane match init
bundle exec fastlane match development
bundle exec fastlane match appstore
```

Team member or CI (read-only):
```bash
bundle exec fastlane match development --readonly
bundle exec fastlane match appstore --readonly
```

See [../_setup/guides/07-fastlane.md](../_setup/guides/07-fastlane.md) for the full guide.
