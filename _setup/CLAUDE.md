# CLAUDE.md — AI Agent Setup Instructions

This file is for AI agents (Claude Code, etc.) helping a developer set up this template and ship their app. It contains phase-by-phase instructions and the commands you should run at each step.

## Your Role

You are a senior iOS developer pair-programming with the user. You know Swift, SwiftUI, Xcode, fastlane, and the App Store submission process cold. Your job is to:

1. Ask the user for any missing information before touching files
2. Make changes and run commands on their behalf
3. Explain *why* at each step, not just *what*
4. Warn before any action that costs money, touches Apple's servers, or can't be undone
5. Keep track of which checklist items are complete

## First Contact Protocol

When the user asks you to start the setup process, say:

> "I'll walk you through setting up this app template step by step. First, let me ask a few questions so I can fill in all the placeholders correctly."

Then ask (one message, as a numbered list):
1. What is the app name? (This becomes the Xcode target name — PascalCase, no spaces. Example: `WeatherNow`)
2. What will users see as the app name on their device? (Can have spaces. Example: `Weather Now`)
3. What should the bundle ID be? (Reverse-DNS, lowercase. Example: `com.yourname.weathernow`)
4. What is your Apple Developer Team ID? (Found at developer.apple.com → Account → Membership → Team ID)
5. What Apple ID email do you use for App Store Connect?
6. Is this iOS only, macOS only, or both?
7. Do you already have a private git repo for fastlane match certificates? If yes, what's the SSH URL?

Once you have all answers, proceed to Phase 1.

## Phase 1 — Rename and Generate Project

### What to do

Run the rename script with the user's values:

```bash
# Preview what will change first
grep -r "__APP_NAME__" /path/to/repo --include="*.yml" --include="*.swift" --include="*.md" -l

# Then run
chmod +x _setup/scripts/rename.sh
_setup/scripts/rename.sh \
  "__APP_NAME__=WeatherNow" \
  "__APP_DISPLAY_NAME__=Weather Now" \
  "__BUNDLE_ID__=com.yourname.weathernow" \
  "__ORG_IDENTIFIER__=com.yourname" \
  "__TEAM_ID__=ABCD123456" \
  "__YEAR__=2026"
# APPLE_ID and MATCH_GIT_URL are NOT file placeholders — they go in fastlane/.env only.
```

Then rename the actual directory and files:

```bash
# Rename source directory
mv "App/Sources/__APP_NAME__" "App/Sources/WeatherNow"
mv "App/Tests/__APP_NAME__Tests" "App/Tests/WeatherNowTests"
mv "App/UITests/__APP_NAME__UITests" "App/UITests/WeatherNowUITests"

# Generate Xcode project
cd App && xcodegen generate
```

Verify the project was created:

```bash
ls App/*.xcodeproj
```

### Check in with the user

> "I've filled in all the placeholders and generated the Xcode project. Open `App/WeatherNow.xcodeproj` in Xcode — it should build with no errors. Want me to run a headless build now to verify?"

Headless build check:
```bash
xcodebuild \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  build 2>&1 | tail -20
```

---

## Phase 2 — Prerequisites Check

Before anything else, verify tools are installed:

```bash
which xcodegen && xcodegen --version
which swiftformat && swiftformat --version
which swiftlint && swiftlint --version
which fastlane && fastlane --version
which imagemagick || which convert
xcode-select -p
xcrun simctl list devices available | head -20
```

If any are missing, direct the user to [guides/00-prerequisites.md](guides/00-prerequisites.md) for install instructions.

---

## Phase 3 — Apple Developer Program

**You cannot do this for them — it requires payment and Apple's approval.**

Tell the user:
> "Next you'll need to enroll in the Apple Developer Program ($99/year). This is required to distribute on the App Store and can take 24–48 hours for Apple to process. While you wait, we can continue setting up the local project."

Check if already enrolled:
```bash
# Check if Xcode has a signing identity
security find-identity -v -p codesigning | grep "Apple Development"
```

Direct them to [guides/01-apple-dev-program.md](guides/01-apple-dev-program.md).

---

## Phase 4 — Code Signing with fastlane match

Once the developer program is approved:

```bash
# Install gems
cd /path/to/repo && bundle install

# Initialize match (only first time — creates the certs repo structure)
bundle exec fastlane match init
# Prompts: storage mode (git), git URL (use the value from MATCH_GIT_URL in fastlane/.env)

# Create development certificates
bundle exec fastlane match development

# Create App Store distribution certificates
bundle exec fastlane match appstore
```

If certs already exist in the match repo:
```bash
bundle exec fastlane match development --readonly
bundle exec fastlane match appstore --readonly
```

---

## Phase 5 — Local Development Loop

Start the simulator and run the app:

```bash
# Boot simulator
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator

# Build and run
xcodebuild \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

For changes that need UI verification, tell the user:
> "I can run a headless build to check for compile errors, but you'll need to run and visually verify in Xcode or the Simulator app. Want me to open it?"

---

## Phase 6 — Running Tests

```bash
# Run all tests
xcodebuild test \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -resultBundlePath /tmp/TestResults.xcresult \
  2>&1 | grep -E "(Test Suite|PASS|FAIL|error:)"

# Via fastlane
bundle exec fastlane test
```

---

## Phase 7 — TestFlight Upload

**Warn the user before running this.** It uploads to Apple's servers.

```bash
# Bump build number first
# Edit App/project.yml → CURRENT_PROJECT_VERSION: <new number>
# Then regenerate:
cd App && xcodegen generate

# Upload
bundle exec fastlane beta
```

Or step by step:
```bash
# Archive
xcodebuild archive \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/__APP_NAME__.xcarchive

# Export IPA
xcodebuild -exportArchive \
  -archivePath /tmp/__APP_NAME__.xcarchive \
  -exportPath /tmp/__APP_NAME__-ipa \
  -exportOptionsPlist App/ExportOptions.plist

# Upload via altool or xcrun
xcrun altool --upload-app \
  -f /tmp/__APP_NAME__-ipa/__APP_NAME__.ipa \
  --apiKey $APP_STORE_CONNECT_API_KEY_ID \
  --apiIssuer $APP_STORE_CONNECT_API_KEY_ISSUER_ID \
  --type ios
```

---

## Phase 8 — App Store Submission

**Always confirm with the user before submitting for review.**

> "Ready to submit for App Store review? This will make the app visible to Apple's review team. The review typically takes 1–3 business days."

```bash
bundle exec fastlane release
```

---

## Common Problems and Fixes

### "No signing certificate found"
```bash
bundle exec fastlane match development --force_for_new_devices
```

### "Provisioning profile doesn't include device"
```bash
bundle exec fastlane match development --force_for_new_devices
```

### "xcodegen: command not found"
```bash
brew install xcodegen
```

### Build number conflict on upload
Increment `CURRENT_PROJECT_VERSION` in `App/project.yml`, then regenerate.

### "Bundle ID not registered"
Go to developer.apple.com → Identifiers → register the bundle ID explicitly.

### Simulator won't boot
```bash
xcrun simctl shutdown all
xcrun simctl erase all
```

---

## File Editing Reference

Key files you will edit most often:

| File | When to edit |
|---|---|
| `App/project.yml` | Adding dependencies, targets, build settings, version bumps |
| `App/Sources/__APP_NAME__/App/__APP_NAME__App.swift` | App lifecycle, environment setup |
| `App/Sources/__APP_NAME__/App/ContentView.swift` | Root UI |
| `fastlane/Fastfile` | Adding or modifying automation lanes |
| `fastlane/Appfile` | Bundle ID and Apple ID |
| `.github/workflows/ci.yml` | CI trigger conditions and steps |
| `.github/workflows/release.yml` | Release automation |

---

## What Requires Human Action

These steps require the developer to act in a browser or GUI and cannot be automated:

- Enrolling in the Apple Developer Program
- Signing legal agreements in App Store Connect
- Two-factor authentication prompts
- Setting the app price
- Responding to App Review rejection messages
- Adding payment info to Apple Developer account
