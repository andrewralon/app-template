# 05 — Simulator & Device Testing

How to run your app on the iOS Simulator and physical devices.

---

## iOS Simulator

### Launch via Xcode

1. Select a simulator from the scheme dropdown (next to the ▶ button)
2. Press ⌘R to build and run
3. The Simulator app opens automatically

### Launch via CLI

```bash
# List available simulators
xcrun simctl list devices available

# Boot a specific simulator
xcrun simctl boot "iPhone 16 Pro"

# Open the Simulator app to see it
open -a Simulator

# Launch your app (after it's been installed)
xcrun simctl launch booted com.yourname.myapp
```

### Install an App in the Simulator

```bash
# Build first
xcodebuild \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  build

# Install the .app bundle
xcrun simctl install booted path/to/Build/Products/Debug-iphonesimulator/__APP_NAME__.app

# Launch it
xcrun simctl launch booted __BUNDLE_ID__
```

---

## Common Simulator Management Commands

```bash
# List all simulators (including unavailable)
xcrun simctl list devices

# List available simulators only
xcrun simctl list devices available

# Create a new simulator
xcrun simctl create "iPhone 16 Pro Test" "iPhone 16 Pro" "iOS-18-0"

# Boot a simulator
xcrun simctl boot "iPhone 16 Pro"

# Shut down a simulator
xcrun simctl shutdown "iPhone 16 Pro"

# Shut down all simulators
xcrun simctl shutdown all

# Erase a simulator (reset to factory)
xcrun simctl erase "iPhone 16 Pro"

# Erase all simulators
xcrun simctl erase all

# Get the UDID of the booted simulator
xcrun simctl list devices | grep Booted

# Open URL in simulator
xcrun simctl openurl booted "https://example.com"

# Send a push notification to simulator
xcrun simctl push booted __BUNDLE_ID__ push.json

# Take a screenshot
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# Record video
xcrun simctl io booted recordVideo ~/Desktop/recording.mov
```

---

## Simulator vs. Real Device Differences

The simulator is fast and convenient, but test on real devices too:

| Feature | Simulator | Real Device |
|---|---|---|
| CPU Architecture | x86_64 / ARM64 | ARM64 only |
| Performance | Faster (runs on Mac) | True performance |
| Memory pressure | Not simulated | Real |
| Push Notifications | Simulated (JSON payload) | Real APNS |
| Camera | Not available | Full access |
| Accelerometer/Gyro | Not available | Full access |
| Biometrics | Touch ID simulated | Real Face ID/Touch ID |
| Bluetooth | Not available | Full access |
| NFC | Not available | Full access |
| In-App Purchase | Sandbox environment | Sandbox environment |

**Always test on a real device before submitting to TestFlight or App Store.**

---

## Testing on a Real Device

### Requirements

1. Valid Apple Developer Program membership
2. Device registered in the Developer Portal (or Automatically Manage Signing in Xcode)
3. Development certificate + provisioning profile installed

### Setup

1. Connect device via USB (or use wireless debugging after initial setup)
2. Trust the computer on the device if prompted
3. In Xcode, select your device in the scheme dropdown
4. Press ⌘R — Xcode installs and launches the app

### Wireless Debugging (iOS 14+)

1. Connect device via USB first
2. Xcode → Window → Devices and Simulators → your device → Connect via network
3. Disconnect USB — Xcode maintains the wireless connection
4. Works over WiFi; device and Mac must be on the same network

### Manage Development Devices

```bash
# List connected devices
xcrun xctrace list devices

# Or via instruments
instruments -s devices
```

---

## Simulator: Useful Tricks

### Slow Animations
Debug → Slow Animations (⌘T) — slows all animations so you can see transitions clearly.

### Toggle Dark Mode
```bash
xcrun simctl ui booted appearance dark
xcrun simctl ui booted appearance light
```

Or: Simulator → Features → Toggle Appearance

### Change Status Bar Content
```bash
# Set battery level and WiFi bars for screenshots
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4
```

This is how Apple always shows "9:41" in their marketing screenshots.

### Simulate Location
Simulator → Features → Location → Custom Location... (enter lat/lng)

Or via CLI:
```bash
xcrun simctl location booted set 37.3317 -122.0307  # Apple Park
```

### Simulate Memory Warning
Debug → Simulate Memory Warning

### Inspect View Hierarchy
Debug → View Debugging → Capture View Hierarchy

---

## Simulator for Screenshots

For App Store screenshots, use a pristine simulator with controlled status bar:

```bash
# Boot a clean simulator
xcrun simctl boot "iPhone 16 Pro Max"

# Set perfect status bar
xcrun simctl status_bar "iPhone 16 Pro Max" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4 \
  --dataNetwork "wifi"

# Open app
open -a Simulator
```

See [12-app-icons-screenshots.md](12-app-icons-screenshots.md) for automating this with fastlane snapshot.

---

## Testing Specific iOS Versions

You can test on older iOS versions using older simulator runtimes:

```bash
# List available runtimes
xcrun simctl list runtimes

# Download a specific runtime (in Xcode)
# Xcode → Settings → Platforms → + → iOS XX
```

Or via CLI with xcodes:
```bash
xcodes runtimes
xcodes runtimes install "iOS 16.4"
```

---

## Device Testing Checklist

Before every TestFlight upload, run through:

- [ ] App launches without crash
- [ ] All navigation works (tap every button, every screen)
- [ ] App handles no internet gracefully
- [ ] App handles interrupted calls (switch to Settings and back)
- [ ] Rotate device (if supporting landscape)
- [ ] Dynamic Type (Settings → Accessibility → Display & Text Size → Larger Text)
- [ ] Dark mode looks correct
- [ ] Older device if targeting broad compatibility (test on oldest supported iOS)
- [ ] VoiceOver works at least minimally (Settings → Accessibility → VoiceOver)
