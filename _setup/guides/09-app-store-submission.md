# 09 — App Store Submission

The final step: getting your app in front of everyone. App Review typically takes 1–3 business days for new submissions.

---

## Pre-Submission Checklist

Run through this before clicking Submit:

- [ ] App builds and runs without crashes on a real device
- [ ] All required metadata is filled in App Store Connect
- [ ] Screenshots uploaded for all required device sizes
- [ ] App icon is 1024×1024, no alpha channel
- [ ] Privacy policy URL is set
- [ ] Age rating questionnaire is complete
- [ ] Export compliance answered (or in Info.plist)
- [ ] In-App Purchases are submitted and approved (if applicable)
- [ ] Version number and What's New text is accurate
- [ ] Support URL is live and working
- [ ] App doesn't use private/undocumented APIs
- [ ] All permission usage strings are in Info.plist
- [ ] App doesn't crash at launch
- [ ] App works on the oldest iOS version you claim to support

---

## Required Metadata

Fill these in App Store Connect → your app → your version:

### Text Metadata

| Field | Limit | Tips |
|---|---|---|
| Name | 30 chars | Already set when you created the app |
| Subtitle | 30 chars | Key benefit or tagline |
| Description | 4000 chars | First 252 chars show without "More" |
| Keywords | 100 chars | Comma-separated; no spaces after commas |
| What's New | 4000 chars | Required for every update |
| Support URL | — | Must be live; reviewer will visit it |
| Marketing URL | — | Optional landing page |
| Privacy Policy URL | — | Required for apps with user data or under-13 users |

### Screenshots

Required device sizes (portrait only unless your app supports landscape):

| Device | Resolution | Size Label |
|---|---|---|
| iPhone 16 Pro Max | 1320×2868 | 6.9" |
| iPhone 14 Plus / 15 Plus | 1284×2778 | 6.5" |
| iPhone 8 Plus | 1242×2208 | 5.5" |
| iPad Pro 12.9" (6th gen) | 2064×2752 | 12.9" iPad |

You need at least the 6.9" set for iOS apps. 5.5" is technically optional but strongly recommended (it covers older devices).

See [12-app-icons-screenshots.md](12-app-icons-screenshots.md) for how to generate these.

---

## Submitting via fastlane

```bash
bundle exec fastlane release
```

Or submit only (if build is already uploaded):

```bash
bundle exec fastlane run deliver submit_for_review:true
```

### Deliverfile configuration

`fastlane/Deliverfile` sets defaults for `deliver`:

```ruby
app_identifier "__BUNDLE_ID__"
username ENV.fetch("APPLE_ID", "")  # set in fastlane/.env, never committed

submit_for_review true
automatic_release false  # manually release after approval

# Skip if you're managing these manually
skip_screenshots false
skip_metadata false

force true  # don't ask for confirmation
```

---

## App Review Notes

Sometimes reviewers need context that isn't obvious from the app. Add Review Notes in App Store Connect:

- If your app requires a login: provide demo credentials
- If features depend on hardware not available to reviewers: explain what they're testing
- If your app has a moderated content model: explain the moderation process
- If your app looks empty without data: explain how to trigger the key flows

App Review Notes are only seen by Apple's review team.

---

## Common Rejection Reasons

### 2.1 — App Completeness
App crashes, has placeholder UI ("Lorem ipsum"), or obvious bugs.
**Fix:** Test thoroughly. Remove any stub UI.

### 4.0 — Design: Copycat
App too similar to a built-in Apple app without adding value.
**Fix:** Differentiate clearly.

### 4.2 — Minimum Functionality
App is too simple or doesn't provide enough value.
**Fix:** Add more functionality, or convert to a Safari Extension / web app instead.

### 5.1.1 — Privacy: Data Collection and Storage
Missing usage description strings, or collecting data you don't need.
**Fix:** Add all required `NS*UsageDescription` keys to Info.plist. Only request permissions you actually use.

### 5.1.2 — Privacy: Data Use and Sharing
App Privacy nutrition label doesn't match actual data usage.
**Fix:** Update App Privacy in App Store Connect to accurately reflect all collected data.

### 3.1.1 — In-App Purchase
Directing users to buy outside the app (website purchase for digital content).
**Fix:** All digital goods must go through Apple IAP.

### 2.3.3 — Accurate Metadata
Screenshots don't match the actual app.
**Fix:** Update screenshots to match current UI.

---

## Responding to Rejection

1. Read the rejection message carefully — it usually tells you exactly what to fix
2. Fix the issue
3. Optionally reply via the Resolution Center (App Store Connect → App Review) to clarify if you disagree
4. Resubmit (you don't lose your place in the queue for resubmissions)

If you believe the rejection is wrong, you can appeal: App Store Connect → App Review → your app → Appeal.

---

## Version Management

### Semantic Versioning
Use `MAJOR.MINOR.PATCH`:
- MAJOR: breaking changes or major new features
- MINOR: new features (backward compatible)
- PATCH: bug fixes only

### Build Number Rules
- Must be a positive integer
- Must increase with every upload to the same version slot
- Resets are allowed when the marketing version changes (but usually don't)

### Releasing Updates

1. In App Store Connect, create a new version: Version History → +
2. Enter the new version number (must match `MARKETING_VERSION` in your build)
3. Fill in What's New
4. Upload a build with the new version number
5. Select the build
6. Submit for review

---

## Phased Release

Instead of releasing to all users at once, use Phased Release:

App Store Connect → your version → Phased Release → Enable

Apple gradually rolls out to 1% → 2% → 5% → 10% → 20% → 50% → 100% over 7 days. You can pause or stop the rollout if you detect a crash spike.

---

## After Approval

When your app is approved:
- If "Automatic Release": it goes live immediately or at your scheduled date
- If "Manual Release": go to App Store Connect → version → Release this Version

The app typically appears in the App Store within minutes to a few hours after release, though it can take up to 24 hours to propagate globally.

---

## App Store Optimization (ASO)

Getting your app discovered organically:

- **Name and Subtitle**: include the most searched keywords naturally
- **Keywords field**: use remaining keywords not in your name/subtitle; research competitors
- **Screenshots**: first 3 matter most; use captions; show the core value
- **Ratings**: prompt for reviews at the right moment (after a win, not after an error)
- **Reviews**: respond to all reviews, even negative ones — reviewers can update their rating

Useful ASO research tools: App Annie, Sensor Tower, AppFollow, AppRadar.
