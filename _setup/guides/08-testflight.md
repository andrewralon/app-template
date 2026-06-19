# 08 — TestFlight

TestFlight is Apple's beta testing platform. Internal testers (your team) can test immediately; external testers require a one-time Beta App Review.

---

## How TestFlight Works

1. You upload a build to App Store Connect
2. Apple processes it (5 min to a few hours)
3. Testers install the TestFlight app and your beta
4. Testers can submit feedback and crash reports
5. Each build expires after 90 days

---

## Uploading a Build

### Via fastlane (Recommended)

```bash
bundle exec fastlane beta
```

This handles: match → build → upload in one command.

### Via Xcode

1. Product → Archive (make sure the scheme is set to Release)
2. Xcode Organizer opens automatically
3. Select the archive → Distribute App → App Store Connect
4. Choose: Upload (don't distribute yet) or TestFlight & App Store
5. Follow prompts (automatic signing or manual)
6. Click Upload

### Via command line (xcodebuild + xcrun)

```bash
# Archive
xcodebuild archive \
  -project App/__APP_NAME__.xcodeproj \
  -scheme __APP_NAME__ \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/__APP_NAME__.xcarchive \
  CODE_SIGN_STYLE=Manual \
  PROVISIONING_PROFILE_SPECIFIER="match AppStore __BUNDLE_ID__"

# Export IPA
xcodebuild -exportArchive \
  -archivePath /tmp/__APP_NAME__.xcarchive \
  -exportPath /tmp/__APP_NAME__-ipa \
  -exportOptionsPlist App/ExportOptions.plist

# Upload
xcrun altool --upload-app \
  --file /tmp/__APP_NAME__-ipa/__APP_NAME__.ipa \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
  --apiIssuer "$APP_STORE_CONNECT_API_KEY_ISSUER_ID" \
  --type ios
```

---

## ExportOptions.plist

Required for command-line export. Create at `App/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>__TEAM_ID__</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>__BUNDLE_ID__</key>
        <string>match AppStore __BUNDLE_ID__</string>
    </dict>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

---

## Internal Testing

Internal testers are members of your App Store Connect team.

### Add Internal Testers

1. App Store Connect → your app → TestFlight → Internal Testing
2. Click **+** next to Testers
3. Select team members or enter email addresses of App Store Connect users

Internal builds are available immediately — no Beta App Review required.

**Limit:** 100 internal testers

### Internal Test Groups

Create groups to give specific team members access to specific builds:

1. TestFlight → Internal Testing → Groups → Create Group
2. Add testers to the group
3. Assign builds to the group

---

## External Testing

External testers don't need an App Store Connect account. They receive an invite via email or a public link.

### First-Time Setup: Beta App Review

The first time you create an external test group, your build must pass **Beta App Review**. This is similar to App Review but faster (typically 24–48 hours). Subsequent uploads don't need review unless you've made significant changes.

### Create an External Group

1. App Store Connect → TestFlight → External Testing
2. Click **+** to create a group
3. Name it (e.g., "Public Beta", "Friends & Family")
4. Add the build
5. Fill in: What to Test, Beta App Description (required for external review)
6. Click **Submit for Beta App Review**

### Invite Testers

**Via Email:**
1. After review approval, go to the group
2. Add Testers → enter email addresses (up to 10,000 external testers total)
3. Testers receive an email with a TestFlight link

**Via Public Link:**
1. Group → Enable Public Link
2. Share the link anywhere (website, social media, App Store page)
3. Anyone with the link can install (up to the tester limit)

---

## Managing Builds

### Build Expiration

Each build expires 90 days after upload. Testers will see a warning before expiration.

### What Testers Need

1. Install the **TestFlight app** from the App Store
2. Accept the email invite or follow the public link
3. The app installs like any other app

### Export Compliance

Every upload triggers an export compliance question. For most apps (no encryption), answer No to all encryption questions. If your app uses HTTPS, that's handled by Apple and doesn't count. Add to `Info.plist` to skip the manual question:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

---

## Feedback and Crash Reports

Testers can send feedback directly from TestFlight:

- Shake the device → "Share Feedback" option appears
- Or from within the TestFlight app → tap the app → Send Beta Feedback

Feedback appears in App Store Connect → TestFlight → Feedback.

**Crash Reports:**
- Crashes are automatically collected and appear in App Store Connect → Crashes
- Also visible in Xcode → Window → Organizer → Crashes
- Requires the user to allow device diagnostics sharing

---

## Build Number Strategy

Each upload to TestFlight must have a higher build number than the previous one. Strategies:

| Strategy | Pros | Cons |
|---|---|---|
| Increment by 1 manually | Simple | Conflicts if multiple people build |
| Use timestamp (`date +%s`) | Always unique | Large number |
| Use CI build number | Predictable | Requires CI |
| Read from App Store Connect | Always correct | Slower (API call) |

In `fastlane/Fastfile`, the `beta` lane reads from App Store Connect:

```ruby
latest_build = latest_testflight_build_number(
  api_key: app_store_connect_api_key,
  app_identifier: "__BUNDLE_ID__"
)
increment_build_number(
  build_number: latest_build + 1,
  xcodeproj: "App/__APP_NAME__.xcodeproj"
)
```

---

## What to Test in Beta

Give testers specific scenarios to test, not just "use the app and see what breaks":

```
## What to Test (v1.2, Build 47)

### New features
- [ ] Settings screen → toggle dark mode
- [ ] Swipe left on any list item to delete

### Known issues (please confirm fixed)
- Crash when viewing empty list (fixed in this build)

### Focus areas
- Performance on older devices (iPhone 12 and older)
- Landscape orientation on iPad

### How to report bugs
Shake your device to send feedback, or email beta@yourdomain.com
```

---

## Common Issues

### "Missing compliance" on upload

Add to `Info.plist`:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Build stuck on "Processing"

Normal — wait up to 2 hours. If it stays stuck longer, try uploading again.

### "Invalid signature" on upload

Your distribution certificate or provisioning profile is incorrect. Run:
```bash
bundle exec fastlane match appstore --force
```

### Testers can't find the TestFlight invite

Check their spam folder. Resend from App Store Connect → group → tester → Resend Invite.

### "This app is no longer accepting testers"

The build expired (90 days) or the external group's review was rejected. Upload a new build.
