# 01 — Apple Developer Program

You need an Apple Developer Program membership to distribute apps on the App Store, use TestFlight for external testing, or push to real devices from Xcode without a free provisioning workaround.

**Cost:** $99/year USD  
**Enrollment time:** Minutes to fill out, 24–48 hours for individual approval; longer for organizations

---

## Individual vs. Organization

| Account Type | Who | Notes |
|---|---|---|
| **Individual** | Solo developers | Your legal name appears in the App Store. Cannot transfer app ownership. |
| **Organization** | Companies, teams | Requires D-U-N-S number (free, takes ~5 business days to obtain). Org name appears in App Store. |

For most solo projects, Individual is fine. If you plan to sell the app or work with a team, use Organization.

---

## Enrollment Steps

1. Go to [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/)
2. Sign in with your Apple ID (use the one you plan to use for App Store Connect permanently — it's hard to change later)
3. Select Individual or Organization
4. Fill in personal/business information
5. Accept the Developer Program License Agreement
6. Pay $99 via credit card or PayPal
7. Wait for the confirmation email

For organizations, you'll need to [get a D-U-N-S number](https://developer.apple.com/support/D-U-N-S/) first if you don't have one.

---

## After Approval

### Find Your Team ID

1. Go to [developer.apple.com → Account → Membership](https://developer.apple.com/account/#/membership)
2. Copy your **Team ID** — it's a 10-character alphanumeric string like `ABCD123456`
3. Paste it into your template as `__TEAM_ID__`

### Sign Into Xcode

1. Xcode → Settings (⌘,) → Accounts tab
2. Click **+** → Apple ID
3. Sign in with your developer Apple ID
4. You should see your team listed under the account

### Accept Legal Agreements

New program terms sometimes appear in App Store Connect:

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. If prompted, read and accept any pending agreements
3. **If you don't do this, uploads will fail silently**

---

## App IDs and Bundle Identifiers

An **App ID** registers your bundle identifier with Apple. You need one before distributing.

### Register an Explicit App ID

1. Go to [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** → App IDs → App
3. Select **App** (not App Clip)
4. Description: your app's name
5. Bundle ID: **Explicit** → enter `__BUNDLE_ID__` (e.g. `com.yourname.myapp`)
6. Select capabilities needed (see below)
7. Click Register

### Wildcard vs. Explicit App IDs

- **Explicit** (e.g. `com.acme.myapp`) — required for Push Notifications, iCloud, Sign in with Apple
- **Wildcard** (e.g. `com.acme.*`) — simpler, but can't use those capabilities

Use explicit IDs for production apps.

---

## App Capabilities

Configure capabilities in the App ID *and* in Xcode. They must match.

| Capability | Common Use |
|---|---|
| Push Notifications | Remote push alerts |
| iCloud | CloudKit or document sync |
| Sign in with Apple | "Sign in with Apple" button |
| In-App Purchase | Subscriptions, consumables |
| Game Center | Leaderboards, achievements |
| Associated Domains | Universal Links, Handoff |
| HealthKit | Reading/writing health data |
| HomeKit | Smart home integration |
| App Groups | Sharing data with extensions/widgets |

Enable only what your app actually uses. Unused capabilities complicate review and entitlements.

---

## Certificates (Overview)

Apple uses two types of certificates:

| Type | Purpose |
|---|---|
| **Apple Development** | Build + run on your own devices during development |
| **Apple Distribution** | Archive and upload to App Store / TestFlight |

**Don't create these manually.** Use `fastlane match` — it creates, stores, and syncs them automatically. See [07-fastlane.md](07-fastlane.md).

---

## Provisioning Profiles (Overview)

A provisioning profile links: a certificate + an App ID + specific devices.

| Profile Type | Use |
|---|---|
| Development | Install on registered devices during development |
| Ad Hoc | Install on specific registered devices (up to 100) |
| App Store | Submit to TestFlight and the App Store |

Again, `fastlane match` handles all of this. See [07-fastlane.md](07-fastlane.md).

---

## Registering Test Devices

To install development builds on physical iPhones (outside of TestFlight):

1. Find the device UDID:
   - Connect device → Xcode → Window → Devices and Simulators → copy UDID
   - Or: `system_profiler SPUSBDataType | grep "Serial Number"` (varies by connection type)
2. Go to [developer.apple.com → Devices](https://developer.apple.com/account/resources/devices/list)
3. Click **+** → enter UDID and device name
4. Regenerate provisioning profiles (or let `fastlane match` do it)

Limit: 100 devices per year per device type. The count resets annually.

---

## Common Issues

### "Your account does not have sufficient access"

You enrolled but haven't been approved yet, or you're logged into the wrong Apple ID in Xcode.

### "This account is not eligible"

Your Apple ID may be associated with a different region or your enrollment form had issues. Contact [Apple Developer Support](https://developer.apple.com/contact/).

### "No certificate for team"

Your Apple Developer certificate expired or was revoked. Run `bundle exec fastlane match --force` to recreate.

### Enrollment stuck on "pending"

Individual accounts usually approve within 48 hours on business days. If it's been longer, contact Apple Developer Relations.
