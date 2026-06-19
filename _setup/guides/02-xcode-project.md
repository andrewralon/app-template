# 02 — Xcode Project Setup

This template uses **XcodeGen** to generate the `.xcodeproj` from a YAML definition (`App/project.yml`). You never commit the generated project file — only the YAML source of truth.

---

## Why XcodeGen?

- No merge conflicts in `.xcodeproj` (it's generated, not hand-edited)
- Project structure is readable and reviewable as plain YAML
- Adding files is done in the filesystem; XcodeGen picks them up automatically
- Easy to replicate on CI without checking in generated files

---

## Step 1 — Fill In Placeholders

Before generating, edit `App/project.yml` and replace:

| Placeholder | Your Value |
|---|---|
| `__APP_NAME__` | PascalCase app name, e.g. `WeatherNow` |
| `__APP_DISPLAY_NAME__` | Display name, e.g. `Weather Now` |
| `__BUNDLE_ID__` | Bundle ID, e.g. `com.acme.weathernow` |
| `__TEAM_ID__` | 10-char Team ID from developer.apple.com |

Or use the init script which does this for you:
```bash
_setup/scripts/init.sh
```

---

## Step 2 — Generate the Project

```bash
cd App
xcodegen generate
```

This creates `App/__APP_NAME__.xcodeproj`. Open it:

```bash
open App/__APP_NAME__.xcodeproj
```

---

## Understanding project.yml

```yaml
name: __APP_NAME__
options:
  bundleIdPrefix: __ORG_IDENTIFIER__
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
  generateEmptyDirectories: true
  createIntermediateGroups: true

packages:
  # Add Swift Package dependencies here
  # Example:
  # SDWebImage:
  #   url: https://github.com/SDWebImage/SDWebImage
  #   from: 5.18.0

settings:
  base:
    PRODUCT_BUNDLE_IDENTIFIER: __BUNDLE_ID__
    MARKETING_VERSION: 1.0.0
    CURRENT_PROJECT_VERSION: 1
    SWIFT_VERSION: 5.10
    DEVELOPMENT_TEAM: __TEAM_ID__
    SWIFT_STRICT_CONCURRENCY: complete
    ENABLE_HARDENED_RUNTIME: YES

targets:
  __APP_NAME__:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Sources/__APP_NAME__
        excludes:
          - "**/*.md"
    settings:
      base:
        PRODUCT_NAME: __APP_DISPLAY_NAME__
        INFOPLIST_FILE: Sources/__APP_NAME__/Resources/Info.plist
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        CODE_SIGN_STYLE: Automatic
    scheme:
      testTargets:
        - __APP_NAME__Tests

  __APP_NAME__Tests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - Tests/__APP_NAME__Tests
    dependencies:
      - target: __APP_NAME__
    settings:
      base:
        INFOPLIST_FILE: ""

  __APP_NAME__UITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - UITests/__APP_NAME__UITests
    dependencies:
      - target: __APP_NAME__
```

---

## Adding Swift Package Dependencies

Add packages in the `packages:` section of `project.yml`, then reference them in your target's `dependencies:`:

```yaml
packages:
  Alamofire:
    url: https://github.com/Alamofire/Alamofire
    from: 5.9.0
  SDWebImageSwiftUI:
    url: https://github.com/SDWebImage/SDWebImageSwiftUI
    from: 3.0.0

targets:
  __APP_NAME__:
    ...
    dependencies:
      - package: Alamofire
      - package: SDWebImageSwiftUI
```

After editing `project.yml`, regenerate:
```bash
cd App && xcodegen generate
```

Xcode will resolve the packages the next time you open the project.

---

## Adding a macOS Target

To support both iOS and macOS (a "multiplatform" app):

```yaml
targets:
  __APP_NAME__:
    type: application
    platform: [iOS, macOS]      # both platforms
    deploymentTarget:
      iOS: "17.0"
      macOS: "14.0"
    ...

  __APP_NAME__macOS:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: Sources/__APP_NAME__
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: __BUNDLE_ID__.macos
```

For a true multiplatform SwiftUI app, most of your `Sources/` folder is shared. Platform-specific code goes in `#if os(iOS)` / `#if os(macOS)` conditionals or separate files.

---

## Source Folder Structure

```
App/Sources/__APP_NAME__/
├── App/
│   ├── __APP_NAME__App.swift    ← @main entry point
│   └── ContentView.swift        ← Root view
├── Features/
│   └── (one folder per feature screen/flow)
├── Shared/
│   ├── Components/              ← Reusable SwiftUI views
│   ├── Extensions/              ← Swift extensions
│   └── Utilities/               ← Helpers, services
└── Resources/
    ├── Assets.xcassets/
    │   ├── AppIcon.appiconset/
    │   └── AccentColor.colorset/
    └── Info.plist
```

### Feature Structure Pattern

Each feature gets its own folder with a consistent internal structure:

```
Features/
└── Home/
    ├── HomeView.swift
    ├── HomeViewModel.swift
    └── HomeModel.swift
```

This makes features self-contained and easy to find.

---

## Build Configurations

XcodeGen creates Debug and Release configurations by default. To add a custom Staging configuration:

```yaml
configs:
  Debug: debug
  Staging: release
  Release: release

settings:
  configs:
    Debug:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
    Staging:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: STAGING
      PRODUCT_BUNDLE_IDENTIFIER: __BUNDLE_ID__.staging
    Release:
      SWIFT_ACTIVE_COMPILATION_CONDITIONS: ""
```

---

## Info.plist

The `Resources/Info.plist` contains app metadata. Key entries:

```xml
<key>CFBundleDisplayName</key>
<string>__APP_DISPLAY_NAME__</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>

<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>

<!-- Required for App Store: explain any sensitive permission usage -->
<key>NSCameraUsageDescription</key>
<string>Used to take profile photos.</string>
```

Add any permission usage descriptions your app needs here. Missing descriptions → App Review rejection.

---

## Version Numbers

| Key | Meaning | Example |
|---|---|---|
| `MARKETING_VERSION` | User-visible version (`CFBundleShortVersionString`) | `1.2.3` |
| `CURRENT_PROJECT_VERSION` | Build number (`CFBundleVersion`) | `42` |

Rules:
- Marketing version uses semantic versioning (major.minor.patch)
- Build number must be an integer, and must increase monotonically for each upload to the same App Store slot
- Two builds with the same marketing version can have different build numbers

Bump both in `project.yml` before each TestFlight/App Store upload:

```yaml
settings:
  base:
    MARKETING_VERSION: 1.1.0
    CURRENT_PROJECT_VERSION: 7
```

Then regenerate: `cd App && xcodegen generate`

---

## .gitignore for Xcode

The repo `.gitignore` already excludes generated files. Key entries:

```
# XcodeGen output
*.xcodeproj
*.xcworkspace

# User-specific
xcuserdata/
*.xccheckout
*.moved-aside
```

Never commit `.xcodeproj` — it's regenerated from `project.yml`.
