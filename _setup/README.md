# _setup — Template Setup Guide

This folder contains everything you need to go from this blank template to a live app on the App Store. Work through it top to bottom, or jump to specific guides as needed.

## How to Use This Template

### Option A — Human-Driven

1. Open [CHECKLIST.md](CHECKLIST.md) and follow the steps in order.
2. Each checklist item links to a guide in [guides/](guides/).
3. Come back to the checklist to tick off completed items.

### Option B — AI Agent (Claude Code)

Open Claude Code in the repo root and say:

> "Read CLAUDE.md and _setup/CLAUDE.md, then help me set up this app template for an app called [your app name]."

The agent will guide you through the process interactively, running commands, editing files, and explaining what it's doing at each step.

---

## Phases

### Phase 0 — Prerequisites (Day 0)

Install the tools you'll need before touching anything in Xcode.

→ [guides/00-prerequisites.md](guides/00-prerequisites.md)

### Phase 1 — Template Initialization (Day 0–1)

Replace all `__PLACEHOLDERS__` with your app's real values and generate the Xcode project.

→ Run `scripts/init.sh`
→ [guides/02-xcode-project.md](guides/02-xcode-project.md)

### Phase 2 — Apple Developer Setup (Day 1)

Enroll in the Apple Developer Program, configure your App ID, and set up code signing certificates.

→ [guides/01-apple-dev-program.md](guides/01-apple-dev-program.md)
→ [guides/07-fastlane.md](guides/07-fastlane.md) (match section)

### Phase 3 — App Store Connect Setup (Day 1–2)

Create the app record in App Store Connect before you can distribute to TestFlight or the App Store.

→ [guides/03-app-store-connect.md](guides/03-app-store-connect.md)

### Phase 4 — Local Development (Ongoing)

Build, run, and iterate on the simulator and real devices.

→ [guides/04-local-development.md](guides/04-local-development.md)
→ [guides/05-simulator-testing.md](guides/05-simulator-testing.md)
→ [guides/06-unit-ui-testing.md](guides/06-unit-ui-testing.md)

### Phase 5 — Beta Testing (When Ready for Feedback)

Upload builds to TestFlight for internal and external testers.

→ [guides/08-testflight.md](guides/08-testflight.md)

### Phase 6 — App Store Submission (When Ready to Ship)

Prepare metadata, screenshots, and submit for App Review.

→ [guides/12-app-icons-screenshots.md](guides/12-app-icons-screenshots.md)
→ [guides/09-app-store-submission.md](guides/09-app-store-submission.md)

### Phase 7 — CI/CD Automation (When You Want Hands-Free Releases)

Set up automated builds, tests, and releases.

→ [guides/10-github-actions.md](guides/10-github-actions.md)
→ [guides/11-xcode-cloud.md](guides/11-xcode-cloud.md)

---

## Folder Contents

```
_setup/
├── README.md          ← This file
├── CHECKLIST.md       ← Master checklist (start here)
├── CLAUDE.md          ← AI agent instructions
├── guides/
│   ├── 00-prerequisites.md
│   ├── 01-apple-dev-program.md
│   ├── 02-xcode-project.md
│   ├── 03-app-store-connect.md
│   ├── 04-local-development.md
│   ├── 05-simulator-testing.md
│   ├── 06-unit-ui-testing.md
│   ├── 07-fastlane.md
│   ├── 08-testflight.md
│   ├── 09-app-store-submission.md
│   ├── 10-github-actions.md
│   ├── 11-xcode-cloud.md
│   └── 12-app-icons-screenshots.md
└── scripts/
    ├── init.sh        ← Interactive setup wizard
    └── rename.sh      ← Find-and-replace all placeholders
```

---

## Key Concepts

### XcodeGen

This template does not commit `.xcodeproj` files. Instead, `App/project.yml` defines the project in YAML, and you run `xcodegen generate` to create it. This avoids merge conflicts and makes the project definition readable.

### fastlane match

Code signing is managed by fastlane `match`, which stores certificates and provisioning profiles in a private git repository. You create that repo once, then every machine and CI runner can pull the same certs.

### Placeholder Convention

All template tokens use double-underscore delimiters: `__LIKE_THIS__`. The `scripts/rename.sh` script replaces them all in one pass.

---

## Timeline Estimate

| Phase | Time (first-timer) | Time (experienced) |
|---|---|---|
| Prerequisites | 1–2 hours | 15 min |
| Template init | 30 min | 10 min |
| Apple Dev setup | 1–3 days (enrollment) | 1 hour |
| App Store Connect | 30 min | 10 min |
| First build on device | 1 hour | 15 min |
| TestFlight upload | 1–2 hours | 30 min |
| App Store submission | 2–4 hours | 1 hour |
| CI/CD setup | 2–4 hours | 1 hour |

*Apple Developer Program enrollment can take up to 48 hours for individual accounts and longer for organizations.*
