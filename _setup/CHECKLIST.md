# App Template Checklist

Work through this top to bottom. Check off each item as you complete it. Items marked ⚠️ require waiting on Apple — plan around them.

> **Hit a snag?** Check `_setup/LESSONS.md` first — it documents known issues and fixes discovered during real use. If you find something new, add it there.

---

## Phase 0 — Prerequisites

- [ ] macOS Sequoia (15+) or Sonoma (14+) installed
- [ ] Xcode 16+ installed (via [xcodes](guides/00-prerequisites.md#xcodes) or Mac App Store)
- [ ] Xcode Command Line Tools installed: `xcode-select --install`
- [ ] Homebrew installed: `/bin/bash -c "$(curl -fsSL https://brew.sh/install.sh)"`
- [ ] Core tools installed: `brew install xcodegen swiftformat swiftlint imagemagick`
- [ ] xcodes installed: `brew install xcodesorg/made/xcodes`
- [ ] GitHub CLI installed: `brew install gh` (then `gh auth login`)
- [ ] rbenv + Ruby 3.3 installed (see [guide](guides/00-prerequisites.md#ruby))
- [ ] fastlane installed: `gem install fastlane`
- [ ] Bundler installed: `gem install bundler`
- [ ] Git configured with your name and email

→ Full details: [guides/00-prerequisites.md](guides/00-prerequisites.md)

---

## Phase 1 — Apple Developer Program

- [ ] ⚠️ Enrolled in Apple Developer Program ($99/yr) at [developer.apple.com](https://developer.apple.com)
- [ ] ⚠️ Enrollment approved (can take 24–48 hours for individuals, longer for orgs)
- [ ] Found your Team ID (developer.apple.com → Account → Membership)
- [ ] Xcode signed in with your Apple ID (Xcode → Settings → Accounts → + )

→ Full details: [guides/01-apple-dev-program.md](guides/01-apple-dev-program.md)

---

## Phase 2 — Template Initialization

The `init.sh` wizard handles most of this automatically. Run it first:
```bash
chmod +x _setup/scripts/init.sh && ./_setup/scripts/init.sh
```

**The wizard will:**
- [ ] Create (or connect) the GitHub repo for your app
- [ ] Collect: app name, display name, bundle ID, Apple ID, Team ID, contact email
- [ ] Create a private GitHub repo for fastlane match certs (or use existing)
- [ ] Compute and fill in GitHub Pages URLs (support + privacy)
- [ ] Replace all `__PLACEHOLDER__` tokens throughout the project
- [ ] Generate the Xcode project (`xcodegen generate`)
- [ ] Generate a placeholder app icon (gradient with first letter)
- [ ] Copy `fastlane/.env.template` → `fastlane/.env` and pre-fill known values
- [ ] Enable GitHub Pages for the `docs/` folder

**After running init.sh:**
- [ ] Opened `App/[AppName].xcodeproj` in Xcode — builds with no errors
- [ ] Filled in remaining secrets in `fastlane/.env`:
  - [ ] `MATCH_PASSWORD` — passphrase for the certs repo
  - [ ] `APP_STORE_CONNECT_API_KEY_ID`
  - [ ] `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - [ ] `APP_STORE_CONNECT_API_KEY_PATH` — path to `.p8` key file
- [ ] Customized `docs/support.html` — replaced placeholder FAQ with real content
- [ ] Reviewed `docs/privacy.html` — updated to reflect actual data practices
- [ ] Verified GitHub Pages live: `curl https://[username].github.io/[repo]/support`

→ Full details: [guides/02-xcode-project.md](guides/02-xcode-project.md)
→ GitHub Pages: [guides/13-github-pages.md](guides/13-github-pages.md)

---

## Phase 3 — App Store Connect Setup

- [ ] Logged into [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Created new App record (Apps → + → New App)
- [ ] Filled in: platform, name, primary language, bundle ID, SKU
- [ ] App ID registered in [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
- [ ] App capabilities configured (if any: Push Notifications, iCloud, etc.)

→ Full details: [guides/03-app-store-connect.md](guides/03-app-store-connect.md)

---

## Phase 4 — Code Signing

- [ ] Created private certs git repo (e.g. `github.com/YOURORG/app-certs`)
- [ ] Ran `bundle exec fastlane match init` and set `MATCH_GIT_URL` in `fastlane/.env`
- [ ] Ran `bundle exec fastlane match development` — development cert + profile created
- [ ] Ran `bundle exec fastlane match appstore` — distribution cert + profile created
- [ ] Xcode shows valid signing identities (no red warnings in project settings)
- [ ] App builds and runs on a real device

→ Full details: [guides/07-fastlane.md](guides/07-fastlane.md)

---

## Phase 5 — Local Development

- [ ] Simulator booting and running: `xcrun simctl boot "iPhone 16 Pro"`
- [ ] App runs in simulator (⌘R in Xcode)
- [ ] App runs on real device (select device in Xcode dropdown → ⌘R)
- [ ] SwiftFormat configured and running: `swiftformat App/Sources`
- [ ] SwiftLint configured and running: `swiftlint App/Sources`
- [ ] `.swiftformat` and `.swiftlint.yml` customized to your preferences

→ Full details: [guides/04-local-development.md](guides/04-local-development.md)
→ [guides/05-simulator-testing.md](guides/05-simulator-testing.md)

---

## Phase 6 — Testing

- [ ] Unit test target builds with no errors
- [ ] At least one unit test written and passing
- [ ] UI test target builds with no errors
- [ ] At least one UI test written and passing
- [ ] All tests pass headlessly: `xcodebuild test -scheme __APP_NAME__ -destination '...'`

→ Full details: [guides/06-unit-ui-testing.md](guides/06-unit-ui-testing.md)

---

## Phase 7 — App Icon & Screenshots

- [ ] App icon designed (1024×1024 PNG, no alpha, no rounded corners — Apple does that)
- [ ] Icon placed at `App/Sources/__APP_NAME__/Resources/Assets.xcassets/AppIcon.appiconset/`
- [ ] App icon shows correctly in simulator and on device
- [ ] Screenshot frames designed or generated with `fastlane snapshot` + ImageMagick
- [ ] Screenshots exported for all required device sizes (6.9", 6.5", 5.5", iPad if needed)

→ Full details: [guides/12-app-icons-screenshots.md](guides/12-app-icons-screenshots.md)

---

## Phase 8 — TestFlight

- [ ] Archive built: Product → Archive in Xcode (or `bundle exec fastlane beta`)
- [ ] Build uploaded to App Store Connect
- [ ] ⚠️ Build processed by Apple (usually 5–30 min; can be hours)
- [ ] Internal testers (team members) added and notified
- [ ] ⚠️ External test group created and submitted for Beta App Review (24–48 hr)
- [ ] External testers added and can install via TestFlight

→ Full details: [guides/08-testflight.md](guides/08-testflight.md)

---

## Phase 9 — App Store Submission

- [ ] App Store metadata filled in (description, keywords, category, support URL)
- [ ] App Store screenshots uploaded for all required sizes
- [ ] Privacy policy URL set
- [ ] App Review notes written (if needed)
- [ ] Age rating questionnaire completed
- [ ] Pricing set (Free or paid tier selected)
- [ ] Build selected for submission
- [ ] ⚠️ Submitted for App Review (typically 1–3 days for first submission)
- [ ] ⚠️ App Review approved
- [ ] App released to the App Store

→ Full details: [guides/09-app-store-submission.md](guides/09-app-store-submission.md)

---

## Phase 10 — CI/CD (Optional but Recommended)

- [ ] GitHub Actions secrets set in repo Settings → Secrets → Actions:
  - [ ] `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_PRIVATE_KEY`
  - [ ] `APPLE_ID`, `APPLE_TEAM_ID`
  - [ ] `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT`
  - [ ] `KEYCHAIN_PASSWORD`
- [ ] `ci.yml` workflow runs on PRs and passes
- [ ] `release.yml` workflow triggers on version tag and uploads to TestFlight
- [ ] Optional: Xcode Cloud configured as alternative CI

→ [guides/10-github-actions.md](guides/10-github-actions.md)
→ [guides/11-xcode-cloud.md](guides/11-xcode-cloud.md)

---

## Post-Ship Housekeeping

- [ ] Version bumped in `App/project.yml` (MARKETING_VERSION + CURRENT_PROJECT_VERSION)
- [ ] CHANGELOG updated
- [ ] Git tag pushed: `git tag v1.0.0 && git push --tags`
- [ ] App Store listing updated with any new screenshots
- [ ] Analytics / crash reporting SDK integrated (if desired)
- [ ] Feedback channel set up (email, Discord, etc.)
- [ ] Run `_setup/scripts/cleanup.sh` and commit — removes setup scaffolding from the app repo
