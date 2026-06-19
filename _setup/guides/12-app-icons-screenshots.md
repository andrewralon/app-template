# 12 — App Icons & Screenshots

Your app icon and screenshots are the first things potential users see. This guide covers creating them correctly and automating them with fastlane + ImageMagick.

---

## App Icon Requirements

### Specs

| Property | Requirement |
|---|---|
| Size | 1024×1024 pixels |
| Format | PNG (no JPEG) |
| Color space | sRGB or P3 |
| Alpha channel | **None** — transparent backgrounds are rejected |
| Rounded corners | **Don't add** — Apple does this automatically |
| Layers | Flattened |

### Design Tips

- **Works at every size**: Your icon renders at sizes from 29×29 (Settings) to 1024×1024 (App Store). Test small.
- **Simple and recognizable**: One focused concept. Avoid text.
- **Distinctive silhouette**: Should be recognizable in grayscale or outline form.
- **No Apple imagery**: Don't use the Apple logo, iPhone outlines, or other Apple-proprietary graphics.
- **No screenshots**: The icon is not a preview of your app's UI.
- **Avoid words**: App name is shown below the icon; don't repeat it inside.

### Creating the Icon

Free tools:
- [Sketch](https://www.sketch.com/) (paid, $10/mo)
- [Figma](https://figma.com/) (free tier available)
- [Canva](https://canva.com/) (free tier available)
- [Pixelmator Pro](https://www.pixelmator.com/pro/) (Mac, $49 one-time)

### Adding to the Project

1. Place your 1024×1024 PNG at: `App/Sources/__APP_NAME__/Resources/Assets.xcassets/AppIcon.appiconset/`
2. Name it: `Icon-1024.png`
3. Update `Contents.json` in that folder (template already includes the correct format for Xcode 16)

Xcode will automatically scale the icon to all required sizes from the single 1024×1024 source.

### Generate All Sizes (Optional — Done Automatically)

If you need explicit files for any reason:

```bash
# Using ImageMagick, generate all standard iOS icon sizes
ICON="App/Sources/__APP_NAME__/Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"

sizes=(20 29 40 58 60 76 80 87 120 152 167 180 1024)
for size in "${sizes[@]}"; do
  convert "$ICON" -resize "${size}x${size}" \
    "App/Sources/__APP_NAME__/Resources/Assets.xcassets/AppIcon.appiconset/Icon-${size}.png"
done
```

---

## Screenshots

### Required Sizes for New Apps (2026)

| Device | Resolution | Required? |
|---|---|---|
| iPhone 16 Pro Max | 1320×2868 (portrait) | **Required** (6.9") |
| iPhone 14 Plus / 15 Plus | 1284×2778 (portrait) | Optional (6.5") |
| iPhone 8 Plus | 1242×2208 (portrait) | **Required** for older device support |
| iPad Pro 12.9" (6th gen) | 2064×2752 (portrait) | Required if iPad supported |
| iPad Pro 11" (4th gen) | 1668×2388 (portrait) | Optional |

**Tip:** 6.9" screenshots also satisfy the 6.5" requirement. You can submit 6.9" for both slots.

### Screenshot Content Rules

- Must show the actual app UI (no hands, no devices by default — but device mockups are allowed)
- Must be accurate to the current version
- No pricing, no time-sensitive information
- No references to other platforms ("Like it? Leave an Android review!")
- Up to 10 screenshots per device size

---

## Automated Screenshots with fastlane snapshot

`fastlane snapshot` runs your UI test suite to capture screenshots automatically.

### Setup

1. Add a `SnapshotHelper.swift` file to your UI test target:

```bash
bundle exec fastlane snapshot init
```

This adds `SnapshotHelper.swift` to your project directory. Add it to your UITest target in Xcode.

2. Add screenshot capture to your UI tests:

```swift
// UITests/__APP_NAME__UITests/SnapshotTests.swift
import XCTest

final class SnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["--uitesting", "--snapshot"]
        app.launch()
    }

    func testHomeScreenshot() {
        snapshot("01-Home")
    }

    func testDetailsScreenshot() {
        let app = XCUIApplication()
        app.cells.firstMatch.tap()
        snapshot("02-Detail")
    }

    func testSettingsScreenshot() {
        let app = XCUIApplication()
        app.tabBars.buttons["Settings"].tap()
        snapshot("03-Settings")
    }
}
```

3. Configure `fastlane/Snapfile`:

```ruby
# fastlane/Snapfile
devices([
  "iPhone 16 Pro Max",
  "iPhone 14 Plus",
  "iPhone 8 Plus",
  "iPad Pro (12.9-inch) (6th generation)"
])

languages(["en-US"])

scheme "__APP_NAME__UITests"
project "App/__APP_NAME__.xcodeproj"

output_directory("fastlane/screenshots")
clear_previous_screenshots(true)

# Perfect status bar for every screenshot
override_status_bar(true)
```

4. Run:

```bash
bundle exec fastlane screenshots
```

---

## Device Frames with frameit

`frameit` wraps screenshots in realistic device frames.

```bash
# Install frameit dependency
bundle exec fastlane frameit setup

# Frame all screenshots
bundle exec fastlane frameit silver  # silver frame
bundle exec fastlane frameit gold    # gold frame
bundle exec fastlane frameit black   # space black frame
```

### Adding Text Captions

Create `fastlane/screenshots/Framefile.json`:

```json
{
  "device_frame_version": "latest",
  "default": {
    "keyword": {
      "font": "/System/Library/Fonts/Helvetica.ttc",
      "color": "#000000",
      "size": "130"
    },
    "title": {
      "font": "/System/Library/Fonts/Helvetica.ttc",
      "color": "#FFFFFF",
      "size": "80"
    },
    "background": "./backgrounds/background.jpg",
    "padding": 50,
    "show_complete_frame": false,
    "stack_title": false,
    "title_below_image": true
  },
  "data": [
    {
      "filter": "01-Home",
      "keyword": { "text": "Effortless" },
      "title": { "text": "Track anything, anywhere" }
    },
    {
      "filter": "02-Detail",
      "keyword": { "text": "Beautiful" },
      "title": { "text": "Stunning details at a glance" }
    }
  ]
}
```

---

## Screenshot Production with ImageMagick

For custom screenshot compositions (text overlays, backgrounds, multi-device mockups):

```bash
# Composite a screenshot on top of a background
convert background.png screenshot.png \
  -gravity Center \
  -geometry +0+100 \
  -composite \
  output.png

# Add text overlay
convert screenshot.png \
  -font Helvetica-Bold \
  -pointsize 80 \
  -fill white \
  -gravity North \
  -annotate +0+120 "Your headline here" \
  output.png

# Resize to exact required dimensions
convert screenshot.png -resize 1320x2868^ \
  -gravity center \
  -extent 1320x2868 \
  screenshot-6.9.png

# Batch process all screenshots
for f in fastlane/screenshots/en-US/*.png; do
  name=$(basename "$f" .png)
  convert "$f" \
    -resize 1320x2868^ \
    -gravity center \
    -extent 1320x2868 \
    "fastlane/screenshots/en-US/framed/${name}.png"
done
```

---

## fastlane Lane for Full Screenshot Flow

In `fastlane/Fastfile`:

```ruby
lane :screenshots do
  # 1. Capture raw screenshots via UI tests
  capture_screenshots(
    project: "App/__APP_NAME__.xcodeproj",
    scheme: "__APP_NAME__UITests",
    devices: ["iPhone 16 Pro Max", "iPhone 8 Plus"],
    languages: ["en-US"],
    output_directory: "fastlane/screenshots",
    clear_previous_screenshots: true,
    override_status_bar: true
  )

  # 2. Frame in device bezels
  frame_screenshots(
    silver: true,
    path: "fastlane/screenshots"
  )
end
```

Run the whole thing:
```bash
bundle exec fastlane screenshots
```

---

## Uploading Screenshots

### Via fastlane deliver

```bash
bundle exec fastlane deliver --skip_binary_upload --skip_metadata
```

Or as part of the full release:
```bash
bundle exec fastlane release
```

### Manually in App Store Connect

1. App Store Connect → your app → your version → App Preview and Screenshots
2. Select device size
3. Drag and drop screenshot files
4. Drag to reorder (first 3 are shown in search results)

---

## App Icon Validation

Before submitting, validate your icon won't get rejected:

```bash
# Check for alpha channel (should output 0 for no alpha)
identify -verbose your-icon.png | grep -i alpha

# If it has alpha, remove it:
convert your-icon.png -background white -flatten no-alpha-icon.png

# Verify dimensions
identify -format "%wx%h\n" your-icon.png  # should output: 1024x1024
```
