# 11 — Xcode Cloud

Xcode Cloud is Apple's native CI/CD, built into Xcode and App Store Connect. It's simpler than GitHub Actions (no SSH key juggling for code signing) but costs money after the free tier.

---

## Xcode Cloud vs. GitHub Actions

| | Xcode Cloud | GitHub Actions |
|---|---|---|
| Code signing | Automatic (Apple manages it) | Manual (fastlane match) |
| Setup complexity | Low | Medium |
| Cost | $14.99–$99.99/mo (see below) | Free for public repos; $0.008/min for macOS |
| Triggers | Xcode and App Store Connect | GitHub events, tags |
| Integration | Native Xcode UI | YAML workflows |
| Notifications | App Store Connect, Xcode | GitHub, Slack, email |
| Best for | Teams already in the Apple ecosystem | Teams preferring GitHub-native workflows |

### Pricing (as of 2026)

| Tier | Compute hours/mo | Price |
|---|---|---|
| Free | 25 | $0 (first year for new members) |
| Starter | 100 | $14.99 |
| Small | 250 | $29.99 |
| Medium | 500 | $49.99 |
| Large | 1000 | $99.99 |

A typical build + test cycle takes ~10–20 minutes. 25 hours = ~75–150 builds/month.

---

## Getting Started

### Prerequisites
- Xcode 13+ (Xcode Cloud launched with Xcode 13)
- App record created in App Store Connect
- Code hosted on GitHub, Bitbucket, or GitLab

### First Setup

1. In Xcode: Product → Xcode Cloud → Create Workflow
2. Select your app and connect your source repository
3. Xcode Cloud requests access to your git host
4. Choose your first workflow triggers
5. Grant App Store Connect access
6. Click "Start Build"

---

## Workflows

Xcode Cloud workflows are configured in Xcode (not YAML), but this template includes `ci_scripts/` for custom steps.

### Default Workflow (CI)

Configure in Xcode → Report Navigator → Cloud → Manage Workflows:

**Triggers:**
- Branch changes: `main`, `feature/**`
- Pull Requests: any target branch

**Actions:**
1. Build → iOS Simulator
2. Test → iPhone 16 Pro (Xcode Cloud manages the simulator)
3. Analyze (optional, catches static analysis issues)

**Post-Actions:**
- Notify on success/failure

### Release Workflow

**Triggers:**
- Tag changes: `v*`

**Actions:**
1. Build → Any iOS Device
2. Test → iPhone 16 Pro
3. Archive
4. TestFlight (Internal Testing) — auto-distribute to internal testers

---

## CI Scripts

Xcode Cloud runs optional scripts at specific points in the build lifecycle. This template includes them in `ci_scripts/`:

```
ci_scripts/
├── ci_post_clone.sh        ← After repo clone, before build
├── ci_pre_xcodebuild.sh    ← Just before xcodebuild runs
└── ci_post_xcodebuild.sh   ← After xcodebuild (success or failure)
```

These files must be in the `ci_scripts/` directory **at the root of your repository** and must be executable.

### ci_post_clone.sh

Runs after Xcode Cloud clones your repo. Use it to install tools and generate the Xcode project:

```bash
#!/bin/sh
set -e

# Install XcodeGen
brew install xcodegen

# Generate the Xcode project from project.yml
cd App
xcodegen generate
```

### ci_pre_xcodebuild.sh

Runs just before the build. Use it for last-minute configuration:

```bash
#!/bin/sh
set -e

# Example: set build number from CI build number
if [ -n "$CI_BUILD_NUMBER" ]; then
    /usr/libexec/PlistBuddy \
        -c "Set :CFBundleVersion $CI_BUILD_NUMBER" \
        "App/Sources/__APP_NAME__/Resources/Info.plist"
fi
```

### ci_post_xcodebuild.sh

Runs after the build, regardless of success or failure. Use it for cleanup or notifications:

```bash
#!/bin/sh
# Example: collect test results

if [ "$CI_XCODEBUILD_EXIT_CODE" -ne 0 ]; then
    echo "Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
fi
```

---

## Environment Variables in Xcode Cloud

Xcode Cloud provides built-in environment variables:

| Variable | Value |
|---|---|
| `CI_WORKSPACE` | Path to the workspace |
| `CI_BUILD_NUMBER` | Build number (auto-incremented) |
| `CI_PRODUCT` | Product name |
| `CI_BUNDLE_ID` | Bundle identifier |
| `CI_BRANCH` | Current branch name |
| `CI_TAG` | Current tag (if triggered by tag) |
| `CI_PULL_REQUEST_NUMBER` | PR number (if triggered by PR) |
| `CI_XCODEBUILD_EXIT_CODE` | Exit code of xcodebuild (post-script only) |
| `CI_XCODEBUILD_ACTION` | The xcodebuild action (build, test, archive) |

### Custom Environment Variables

Set custom env vars in Xcode Cloud → workflow → Environment:

1. Xcode → Report Navigator → Cloud → your workflow → Edit
2. Environment → Environment Variables → +
3. Add key/value pairs
4. Check "Secret" for sensitive values (they're encrypted)

---

## Code Signing with Xcode Cloud

One of Xcode Cloud's biggest advantages: it handles code signing automatically.

1. When you set up the workflow, Xcode Cloud asks for App Store Connect access
2. It automatically creates and manages certificates and provisioning profiles
3. No fastlane match needed for Xcode Cloud builds

The profiles it creates are stored in App Store Connect, not in a git repo.

**Note:** If you're also using fastlane match, use `--readonly` on local machines so match doesn't conflict with Xcode Cloud's profiles.

---

## TestFlight Distribution

Configure TestFlight distribution directly in the workflow:

1. Workflow → Actions → Archive → Post-Actions → TestFlight (Internal Testing)
2. Select which internal group gets the build
3. Optionally add an email notification to internal testers

For external testing:
1. The build must pass Beta App Review (same as manual uploads)
2. You can automate promoting from internal to external after a delay

---

## Connecting to GitHub

1. In Xcode Cloud setup, choose GitHub as the source provider
2. Authorize the Xcode Cloud GitHub app
3. Select the repository
4. Xcode Cloud installs a webhook in your GitHub repo to trigger builds on push

To see build status in GitHub PRs:
- Xcode Cloud posts build results back to GitHub as check runs
- PR status checks will show the Xcode Cloud build result

---

## Viewing Build Results

- **Xcode:** Report Navigator (⌘9) → Cloud tab
- **App Store Connect:** Xcode Cloud → Builds
- **Browser:** appstoreconnect.apple.com → Xcode Cloud

Download test result bundles and build logs directly from the build detail page.

---

## Limitations

- Only supports Apple platforms (iOS, macOS, watchOS, tvOS, visionOS)
- Cannot run Docker containers or arbitrary Linux commands
- Script execution time limited to 20 minutes per script phase
- No support for self-hosted runners
- Requires App Store Connect account
