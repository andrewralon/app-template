# 03 — App Store Connect Setup

App Store Connect is Apple's portal for managing your app's listing, uploads, review, pricing, and TestFlight distribution.

**URL:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

---

## Creating a New App

1. Log in to App Store Connect
2. Click **My Apps**
3. Click **+** → **New App**
4. Fill in:

| Field | Notes |
|---|---|
| **Platforms** | iOS, macOS, or tvOS (check all that apply) |
| **Name** | The name shown in the App Store (up to 30 chars). **Can be changed later.** |
| **Primary Language** | Default language for metadata |
| **Bundle ID** | Select the App ID you registered in the Developer Portal. If it's not here, register it first (see [01-apple-dev-program.md](01-apple-dev-program.md)). |
| **SKU** | A private identifier only you see. Use a slug like `myappname-2026`. Cannot change later. |
| **User Access** | Full Access (unless you want to restrict App Store Connect team visibility) |

5. Click **Create**

---

## App Information

After creating the app, fill out the **App Information** section:

- **Subtitle** (optional, up to 30 chars): Shows under your app name in search results. Include a key benefit.
- **Category**: Choose carefully — it affects discoverability. You can set a primary and secondary.
- **Content Rights**: Declare if your app contains third-party content
- **Age Rating**: Complete the questionnaire. Apple calculates this from your answers.
- **Privacy Policy URL**: Required for any app that collects user data, or that targets users under 13. Highly recommended even if not required.

---

## App Store Listing (Per Version)

Each version of your app has its own listing. Fill in:

### App Preview and Screenshots

- Required sizes for iPhone (6.9" = iPhone 16 Pro Max, 6.5" = iPhone 14 Plus, 5.5" = iPhone 8 Plus)
- Optionally: iPad Pro 12.9", iPad Pro 11"
- Up to 10 screenshots per size; first three show in search results
- App previews (videos) are optional but boost conversion

See [12-app-icons-screenshots.md](12-app-icons-screenshots.md) for how to generate these with fastlane + ImageMagick.

### Description

- Up to 4000 characters
- First ~250 characters show without "More" tap — make them count
- Use line breaks for readability
- No markdown; App Store renders it as plain text

### Keywords

- Up to 100 characters total, comma-separated
- Don't repeat words from your app name or title (Apple ignores them)
- Think like a user searching for a solution, not your app name

### What's New

- Required for every update
- Keep it user-focused: "Fixed a bug where X would crash" not "Resolved an edge case in the async coordinator"

### Support URL and Marketing URL

- Support URL is required. Point it to a page where users can get help.
- Marketing URL is optional — your app's landing page or website.

---

## Pricing and Availability

- Go to **Pricing and Availability** in the sidebar
- Select Free or a price tier
- Price tiers are fixed (Tier 1 = $0.99, Tier 2 = $1.99, etc.)
- You can schedule price changes
- Select territories where your app is available (default: all)

---

## App Privacy

Since iOS 14, App Store requires a Privacy Nutrition Label. You must declare what data your app collects and how it's used.

1. In App Store Connect → your app → **App Privacy**
2. Answer the questionnaire for each data category
3. Link data types to their purposes (Analytics, App Functionality, etc.)
4. Declare whether data is linked to identity

This is now required before your app can go on sale. Take it seriously — false declarations can get your app removed.

---

## In-App Purchases and Subscriptions

If your app will have IAP or subscriptions:

1. App Store Connect → your app → **Monetization** → **In-App Purchases** or **Subscriptions**
2. Set up products *before* implementing them in code (the product IDs must match)
3. For subscriptions: create subscription groups, set grace periods, manage offers

Revenue share: Apple takes 30% (15% for small businesses earning < $1M/year via the Small Business Program).

---

## TestFlight Setup

TestFlight configuration lives in App Store Connect too. See [08-testflight.md](08-testflight.md) for the full walkthrough, but the basics:

1. Upload a build (via Xcode, fastlane pilot, or CI)
2. Wait for processing (5–60 minutes)
3. Add internal testers (your team, up to 100) — no review required
4. Create external test groups — requires Beta App Review (24–48 hours, first time only)

---

## App Store Connect API Key

For CI/CD automation (GitHub Actions, Xcode Cloud, fastlane), you need an API key instead of a password.

1. App Store Connect → Users and Access → **Integrations** → **App Store Connect API**
2. Click **Generate API Key**
3. Name it (e.g., `CI-Automation`)
4. Role: **App Manager** (minimum needed for uploads and TestFlight)
5. Download the `.p8` key file — **you can only download it once**
6. Note the **Key ID** and **Issuer ID** shown on the page

Store these securely:
- Key ID: `APP_STORE_CONNECT_API_KEY_ID`
- Issuer ID: `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
- Key file contents: `APP_STORE_CONNECT_API_KEY_CONTENT` (base64 encode: `cat AuthKey_XXXXX.p8 | base64`)

Add these as GitHub Actions secrets. See [10-github-actions.md](10-github-actions.md).

---

## Team Management

- **Account Holder**: Has full access; tied to the person/entity who enrolled
- **Admin**: Full access except finances
- **App Manager**: Can manage apps but not financials or users
- **Developer**: Limited to certificates and provisioning profiles
- **Marketing**: Can manage app metadata and screenshots
- **Finance**: Can see financial reports only

Invite team members: App Store Connect → Users and Access → **+**

---

## Common Issues

### "Bundle ID not available"

The bundle ID was already taken by another app (even a deleted one). Try a more unique bundle ID.

### "This app cannot be submitted because it's not complete"

Fill in all required metadata: description, screenshots, privacy policy, age rating, support URL.

### Missing required screenshot size

Since iPhone models keep getting larger, App Store sometimes requires screenshots for a new size. Check the required sizes in App Store Connect — they're listed per version.

### "Invalid binary"

Build number conflict (already uploaded a build with this number) or missing export compliance info. Ensure your build number is higher than the last upload and that you've answered the export compliance question.
