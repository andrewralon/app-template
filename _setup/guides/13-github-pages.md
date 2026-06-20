# 13 — GitHub Pages: Support & Privacy Pages

Apple requires a **support URL** and strongly recommends a **privacy policy URL** for every App Store listing. This guide shows how to publish them for free using GitHub Pages — no hosting needed.

---

## What Gets Published

The template's `docs/` folder contains three pages:

| File | URL | Purpose |
|---|---|---|
| `docs/index.html` | `https://username.github.io/reponame/` | App landing page |
| `docs/support.html` | `https://username.github.io/reponame/support` | **Required by App Store** |
| `docs/privacy.html` | `https://username.github.io/reponame/privacy` | Required if collecting data; strongly recommended otherwise |

These are static HTML files — no server, no framework, no build step. They go live the moment GitHub Pages is enabled.

---

## Step 1 — Fill in the Placeholder Content

Before enabling Pages, edit the three HTML files in `docs/`:

### index.html
- Replace the placeholder feature cards with your app's actual features
- Set `__APP_STORE_URL__` to your App Store link (once the app is live)
- The app icon initial (`__APP_NAME_INITIAL__`) is auto-filled by `init.sh`

### support.html
- Replace the placeholder FAQ items with real questions your users will have
- The contact email (`__CONTACT_EMAIL__`) is auto-filled by `init.sh`
- Add your app's version number to the subtitle (or remove it)

### privacy.html
- **Read every section carefully** — the template defaults to "we collect no data"
- If your app uses analytics, crash reporting, or any third-party SDK, uncomment and fill in the relevant sections
- Update the "Last updated" date
- If targeting children (under 13), update the children's section and consult a lawyer

---

## Step 2 — Enable GitHub Pages

### Via GitHub UI
1. Go to your app repo on GitHub
2. Settings → Pages
3. Source: **Deploy from a branch**
4. Branch: `main`, Folder: `/docs`
5. Click Save

Your site will be live at `https://USERNAME.github.io/REPO-NAME/` within a few minutes.

### Via GitHub CLI (automates step 2)
```bash
gh api repos/:owner/:repo/pages \
  --method POST \
  -f source='{"branch":"main","path":"/docs"}' \
  2>/dev/null || echo "Pages may already be enabled"
```

The `init.sh` script does this automatically if `gh` is available and the repo is on GitHub.

---

## Step 3 — Verify Your URLs

After enabling Pages, confirm the pages are live:

```bash
# Should return HTTP 200
curl -s -o /dev/null -w "%{http_code}" https://USERNAME.github.io/REPO-NAME/support
curl -s -o /dev/null -w "%{http_code}" https://USERNAME.github.io/REPO-NAME/privacy
```

It can take 1–5 minutes for Pages to build the first time. If you get a 404, wait a moment and try again.

---

## Step 4 — Add URLs to App Store Connect

1. Go to App Store Connect → your app → App Information
2. **Support URL**: `https://USERNAME.github.io/REPO-NAME/support`
3. **Privacy Policy URL**: `https://USERNAME.github.io/REPO-NAME/privacy`
4. Save

These URLs also go into `fastlane/Deliverfile`:
```ruby
support_url "https://USERNAME.github.io/REPO-NAME/support"
privacy_url "https://USERNAME.github.io/REPO-NAME/privacy"
```

The `init.sh` script fills both of these in automatically.

---

## Important GitHub Pages Notes

### Visibility and Cost

| Repo visibility | GitHub plan | Pages available? |
|---|---|---|
| Public | Free | Yes |
| Private | Free | No |
| Private | GitHub Pro ($4/mo) | Yes |
| Private | GitHub Team/Enterprise | Yes |

**Recommendation**: For a typical indie app, make the app repo **public**. The source code is the app — you're not giving away anything by making it public. This lets you use GitHub Pages for free.

If you prefer a private repo, upgrade to GitHub Pro or use a custom domain with any free static host (Netlify, Vercel, Cloudflare Pages).

### Custom Domain

To use `support.yourapp.com` instead of `username.github.io/yourapp`:

1. Buy a domain (Namecheap, Cloudflare, etc.)
2. Add a `CNAME` record pointing to `username.github.io`
3. In GitHub Pages settings: enter your custom domain
4. Add a `docs/CNAME` file with just your domain: `support.yourapp.com`
5. Enable "Enforce HTTPS" in GitHub Pages settings

---

## Keeping Pages Updated

GitHub Pages automatically re-publishes on every push to `main`. To update your support or privacy page:

```bash
# Edit the HTML file
# Then commit and push
git add docs/
git commit -m "docs: update support FAQ"
git push
```

Changes are live within 1–2 minutes.

---

## App Store URL

Once your app is live on the App Store, update `docs/index.html` with the real URL:

App Store URL format: `https://apps.apple.com/app/id123456789`

Find your App ID in App Store Connect → your app → App Information → Apple ID.

```bash
# Update the placeholder
sed -i '' 's|__APP_STORE_URL__|https://apps.apple.com/app/id123456789|g' docs/index.html
git add docs/index.html
git commit -m "docs: add App Store link"
git push
```
