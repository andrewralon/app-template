# app-template

A fill-in-the-blank GitHub template for shipping iOS and macOS apps in Swift — from zero to the App Store.

## What This Is

A batteries-included starting point that handles the scaffolding, tooling, and process documentation so you can focus on building your app. Works equally well whether you're a human developer following guides or an AI agent doing the heavy lifting.

## What's Included

| Area | Tools / Files |
|---|---|
| App scaffold | XcodeGen `project.yml`, SwiftUI source, Assets, Info.plist |
| Code signing | fastlane `match` (certs + profiles in a private git repo) |
| Screenshots | fastlane `snapshot` + ImageMagick framing |
| Beta distribution | fastlane `pilot` → TestFlight |
| App Store delivery | fastlane `deliver` |
| CI (GitHub Actions) | Build + test on every PR; release to TestFlight on tag |
| CI (Xcode Cloud) | Alternative cloud build scripts |
| Setup guides | Step-by-step docs covering the full journey |
| AI agent support | `CLAUDE.md` at every level for agent-driven setup |

## Quick Start

### Prerequisites

```bash
# Xcode (from Mac App Store or xcodes)
brew install xcodesorg/made/xcodes

# Core tools
brew install xcodegen swiftformat swiftlint imagemagick

# Ruby + fastlane
brew install rbenv
rbenv install 3.3.0 && rbenv global 3.3.0
gem install fastlane
```

### 1. Use This Template

Click **"Use this template"** on GitHub, or clone and re-init:

```bash
git clone https://github.com/YOUR_ORG/app-template.git my-app
cd my-app
git remote set-url origin https://github.com/YOUR_ORG/my-app.git
```

### 2. Run the Init Script

```bash
chmod +x _setup/scripts/init.sh
./_setup/scripts/init.sh
```

The script walks you through filling in all placeholders and generates your Xcode project.

### 3. Follow the Checklist

Open [_setup/CHECKLIST.md](_setup/CHECKLIST.md) and work through it top to bottom. Each item links to a detailed guide.

## Template Placeholders

**File placeholders** — replaced in committed files by `rename.sh` / `init.sh`:

| Placeholder | Example | Description |
|---|---|---|
| `__APP_NAME__` | `MyGreatApp` | Xcode target / Swift type name (PascalCase, no spaces) |
| `__APP_DISPLAY_NAME__` | `My Great App` | Human-readable name shown on device |
| `__BUNDLE_ID__` | `com.acme.mygreatapp` | Reverse-DNS bundle identifier |
| `__ORG_IDENTIFIER__` | `com.acme` | Bundle ID prefix |
| `__TEAM_ID__` | `ABC123DEF4` | 10-char Apple Developer Team ID |
| `__YEAR__` | `2026` | Current year for copyright |

**Env vars** — written to `fastlane/.env` only, never committed:

| Variable | Description |
|---|---|
| `APPLE_ID` | Apple ID email for App Store Connect |
| `APPLE_TEAM_ID` | 10-char Apple Developer Team ID (same value as `__TEAM_ID__`, used by fastlane) |
| `MATCH_GIT_URL` | SSH URL of private git repo for fastlane match certs |
| `MATCH_PASSWORD` | Passphrase to encrypt the certs repo |
| `APP_STORE_CONNECT_API_KEY_*` | App Store Connect API key (see `fastlane/.env.template`) |

## Directory Structure

```
app-template/
├── _setup/                  ← Start here
│   ├── README.md            ← How to use this template
│   ├── CHECKLIST.md         ← Step-by-step checklist
│   ├── CLAUDE.md            ← AI agent instructions for setup
│   ├── guides/              ← Deep-dive docs for each topic
│   └── scripts/             ← init.sh, rename.sh
│
├── App/                     ← Template Xcode app
│   ├── project.yml          ← XcodeGen project definition
│   ├── Sources/
│   │   └── __APP_NAME__/    ← Rename to your app name
│   │       ├── App/         ← Entry point + root view
│   │       ├── Features/    ← Feature modules
│   │       ├── Shared/      ← Reusable components / extensions
│   │       └── Resources/   ← Assets, Info.plist
│   ├── Tests/
│   └── UITests/
│
├── fastlane/                ← Fastlane configuration
├── .github/workflows/       ← GitHub Actions CI/CD
└── ci_scripts/              ← Xcode Cloud build scripts
```

## Guides

See [_setup/guides/](_setup/guides/) for detailed walkthroughs:

- [00 — Prerequisites](_setup/guides/00-prerequisites.md)
- [01 — Apple Developer Program](_setup/guides/01-apple-dev-program.md)
- [02 — Xcode Project Setup](_setup/guides/02-xcode-project.md)
- [03 — App Store Connect](_setup/guides/03-app-store-connect.md)
- [04 — Local Development](_setup/guides/04-local-development.md)
- [05 — Simulator & Device Testing](_setup/guides/05-simulator-testing.md)
- [06 — Unit & UI Testing](_setup/guides/06-unit-ui-testing.md)
- [07 — Fastlane](_setup/guides/07-fastlane.md)
- [08 — TestFlight](_setup/guides/08-testflight.md)
- [09 — App Store Submission](_setup/guides/09-app-store-submission.md)
- [10 — GitHub Actions CI/CD](_setup/guides/10-github-actions.md)
- [11 — Xcode Cloud](_setup/guides/11-xcode-cloud.md)
- [12 — App Icons & Screenshots](_setup/guides/12-app-icons-screenshots.md)

## Using With an AI Agent

If you're using Claude Code or another AI agent to build this app, start the agent in this directory and say:

> "Read CLAUDE.md and _setup/CLAUDE.md, then help me set up this app template."

The agent will guide you through the entire process interactively.

---

*Built to be replaced. Every `__PLACEHOLDER__` in this repo is meant to become your app.*
