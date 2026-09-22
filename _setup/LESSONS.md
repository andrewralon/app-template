# Template Lessons Learned

Issues discovered during real use. Each entry has the symptom, root cause, and the fix applied to the template.

---

## 1. `rename.sh` fails on macOS with system bash (bash 3.2)

**Symptom:** Running `_setup/scripts/rename.sh` immediately errors:
```
declare: -A: invalid option
```

**Root cause:** `declare -A` creates an associative array — a bash 4.0+ feature. macOS ships bash 3.2 and will not update it (GPLv3 license conflict). The script shebang `#!/usr/bin/env bash` resolves to `/bin/bash` (3.2) on a stock Mac.

**Fix applied:** Rewrote `rename.sh` to use parallel indexed arrays (`keys_arr`, `vals_arr`) — bash 3.2 compatible. Also rewrote the FIND_ARGS construction to avoid the `unset arr[${#arr[@]}-1]` pattern (arithmetic in array subscripts is also unreliable in bash 3.2).

**Workaround if not yet fixed:** `brew install bash && /opt/homebrew/bin/bash _setup/scripts/rename.sh ...`

---

## 2. `rename.sh` modifies itself, corrupting template logic

**Symptom:** After running the rename script, `_setup/scripts/rename.sh` contains literal app values (`sevensim`, `com.andrewralon.7-sim`) where it used to say `__APP_NAME__`, breaking the script for any future re-run or inspection.

**Root cause:** `find "$REPO_ROOT"` includes `_setup/scripts/rename.sh` itself. The script replaces `__APP_NAME__` globally, including in its own source.

**Fix applied:** Added `[ "$file" = "$THIS_SCRIPT" ] && continue` to skip the script file during replacement.

---

## 3. `rename.sh` corrupts `_setup/` instruction files and `CLAUDE.md`

**Symptom:** After running the rename script, `_setup/CLAUDE.md`, `_setup/CHECKLIST.md`, and the root `CLAUDE.md` contain the actual app values in their example code blocks. For example, the example command that previously read:
```bash
rename.sh "__APP_NAME__=WeatherNow"
```
becomes:
```bash
rename.sh "sevensim=WeatherNow"
```
...making the agent instructions and checklist confusing or broken for future use.

**Root cause:** The rename script's `find` covers the entire repo, including template meta-files. These files intentionally contain placeholder tokens as *examples* — not as values to be replaced.

**Fix applied:** Added `-not -path "*/_setup/*"` and `-not -name "CLAUDE.md"` exclusions to the find command in `rename.sh`. These files are developer/agent documentation, not app source.

---

## 4. `__APP_NAME__` must be a valid Swift identifier

**Symptom:** User wanted their app named `7-sim` for everything. The rename script was initially called with `__APP_NAME__=7-sim`, which would break the build: Swift type names can't start with a digit or contain hyphens (`sevensimApp`, `sevensimTests` are the generated struct/class names).

**Root cause:** The first-contact questions in `_setup/CLAUDE.md` ask for "PascalCase, no spaces" but don't explicitly warn about digits and hyphens.

**Fix applied (documentation):** The first-contact question for `__APP_NAME__` should explicitly say:
> Must be a valid Swift identifier: letters and digits only, cannot start with a digit. Example: `WeatherNow`. (The display name and repo name can differ — e.g., display name `Weather Now`, repo name `weather-now`.)

---

## 5. `__CONTACT_EMAIL__` and `__DEVELOPER_NAME__` assumed required

**Symptom:** Template assumes every app will have a public contact email and a developer name in the privacy policy. Some developers prefer GitHub issues for support and don't want to disclose a name.

**Root cause:** `docs/support.html` and `docs/privacy.html` hard-wire an email-only contact pattern.

**Fix applied (for this app):** Edited the HTML files before running the rename script to replace the email `<a>` tag with a GitHub issues link and removed the `__DEVELOPER_NAME__` sentence from the privacy policy overview.

**Suggested template improvement:** Make `__CONTACT_EMAIL__` optional in the first-contact questions. Add a commented-out GitHub issues block in `support.html` and `privacy.html` as an alternative to the mailto block. Note in `_setup/CLAUDE.md` that both options exist.

---

## 6. `__APP_VERSION__` placeholder in `support.html` not handled by `rename.sh`

**Symptom:** `support.html` had `Version __APP_VERSION__` in the subtitle but `__APP_VERSION__` is not in the rename script's variable list and has no default value provided to the script. It would be left as a literal string.

**Root cause:** Version numbers change with every release and aren't known at setup time — so it can't be filled in once. It probably shouldn't be a static placeholder at all.

**Fix applied (for this app):** Removed `· Version __APP_VERSION__` from the subtitle entirely. The support page doesn't need a version number hardcoded.

**Suggested template improvement:** Either remove `__APP_VERSION__` from `support.html`, or replace it with a comment instructing developers to update it manually per release.

---

## 7. No cleanup mechanism for template scaffolding

**Symptom:** After the app is set up and shipping, `_setup/` (guides, scripts, lessons) and the template-flavored `README.md` and `CLAUDE.md` remain in the app repo permanently. Developers either forget to clean them up or don't know they should.

**Root cause:** The template had no post-setup cleanup step in the checklist or scripts.

**Fix applied:** Created `_setup/scripts/cleanup.sh`. Run it once the app builds, signs, and ships:
```bash
./_setup/scripts/cleanup.sh
git add -A && git commit -m "Remove template scaffolding"
```
It removes `_setup/`, removes the root `CLAUDE.md` (template agent instructions), and replaces `README.md` with a minimal app-specific stub.

**Suggested template improvement:** Add to `_setup/CHECKLIST.md` under Post-Ship Housekeeping:
```
- [ ] Run `_setup/scripts/cleanup.sh` and commit to remove template scaffolding
```

---

## 8. `gh` CLI listed as prerequisite but not verified as installed

**Symptom:** `gh` was listed in Phase 0 prerequisites but wasn't installed on the machine. Any step that calls `gh` (creating repos, enabling Pages) silently fails or errors with `command not found`.

**Root cause:** Phase 2 prerequisites check in `_setup/CLAUDE.md` runs `which xcodegen`, `which fastlane`, etc., but does not check for `gh`. The Phase 0 checklist mentions it but no automated check enforces it.

**Fix applied:** None needed for this app (user will run `gh auth login` manually). `brew install gh` works fine.

**Suggested template improvement:** Add `which gh && gh auth status` to the Phase 2 prerequisites check in `_setup/CLAUDE.md`, alongside the other tool checks.

---

## 9. `rename.sh` skips fastlane files (`Fastfile`, `Appfile`, `Matchfile`, `Deliverfile`)

**Symptom:** After running the rename script, `fastlane/Fastfile`, `fastlane/Appfile`, `fastlane/Matchfile`, and `fastlane/Deliverfile` still contain `__APP_NAME__` and `__BUNDLE_ID__` placeholders. Fastlane lanes fail or behave unexpectedly because they reference the wrong project name and bundle ID.

**Root cause:** The rename script's `find` command filters by file extension (`.swift`, `.yml`, `.rb`, etc.). Fastlane's convention files have no extension, so they are silently skipped.

**Fix applied:** Added a `NAMED_FILES` array to `rename.sh` with `("Fastfile" "Appfile" "Matchfile" "Deliverfile" "Snapfile" "Gymfile" "Scanfile" "Screenshotfile")` and appended `-o -name "$name"` entries to the find `FIND_ARGS`. Both the template and the 7-sim app had placeholders manually replaced with `sed`.

---

## 10. File/directory renames in `rename.sh` used plain `mv`, losing git history

**Symptom:** After running `rename.sh`, renamed files (e.g. `__APP_NAME__App.swift` → `sevensimApp.swift`) appear as delete + add in git history rather than a tracked rename. `git log --follow` can't trace the file's lineage.

**Root cause:** `rename.sh` used plain `mv` for directory and file renames. Git only tracks renames when `git mv` is used (or when git detects similarity above its rename threshold, which isn't guaranteed).

**Fix applied:** Added a `git_mv()` helper to `rename.sh` that calls `git mv` when inside a git repo, falling back to plain `mv` otherwise. The rename script now always produces clean rename entries in git history.

**Recommended setup flow going forward:**
```bash
# Clone template directly into the new app directory
git clone https://github.com/andrewralon/app-template ~/Documents/GitHub/7-sim
cd ~/Documents/GitHub/7-sim

# Point to the new app remote (create the GitHub repo first)
git remote set-url origin https://github.com/andrewralon/7-sim.git

# Run rename (uses git mv — renames are staged automatically)
_setup/scripts/rename.sh "__APP_NAME__=sevensim" ...

# Generate project and commit everything
cd App && xcodegen generate && cd ..
git add .
git commit -m "Initialize from app-template"
git push -u origin main
```
This replaces the rsync + git init approach used in the first 7-sim setup.

---

## 11. App Store Connect app record cannot be created via any API key, at any role

**Symptom:** `fastlane produce`/`create_app_online` fails two different ways depending on what's attempted:
1. Passing `api_key:` directly errors with `Could not find option 'api_key' in the list of available options` — `produce` doesn't accept that parameter at all.
2. Calling `app_store_connect_api_key` first and then running `produce` falls back to interactive Apple ID username/password + 2FA (a live 6-digit-code prompt) — not something CI or an agent session can complete.

A direct, hand-signed call to `POST /v1/apps` (bypassing `produce`/fastlane entirely) gets `403 FORBIDDEN_ERROR — "The resource 'apps' does not allow 'CREATE'. Allowed operations are: GET_COLLECTION, GET_INSTANCE, UPDATE"`. Confirmed with both an App Manager-role key and a freshly generated Admin-role key — identical error either way.

**Root cause:** The official App Store Connect REST API does not support creating a new app record at all, for any key at any role — a permanent Apple platform limitation, not a permissions gap that a more privileged key fixes. `fastlane produce`'s ability to create an app record goes through the older, undocumented "iTunes Connect" API (`Spaceship::Tunes`), authenticated via a real Apple ID session (hence the 2FA) — never the public API-key-authenticated surface. Bundle ID / App ID registration is a separate endpoint (`POST /v1/bundleIds`) with no such restriction — that one works fine with a properly-scoped key (App Manager is sufficient) and no 2FA.

**Fix applied:** Documented this plainly in `_setup/guides/03-app-store-connect.md` (top of "Creating a New App") and added it to the "What Requires Human Action" list in `_setup/CLAUDE.md`: the ASC app record has to be created either by a human in the App Store Connect web UI, or by the developer running `produce`/`create_app_online` interactively themselves (so they can answer the 2FA prompt in their own terminal) — no API key role gets around this, and it can't be deferred to CI or an agent.

---

## 12. `beta`/`release` fastlane lanes corrupted the tracked `Info.plist` and silently lost build-number bumps

**Symptom:** The first `fastlane beta` run on a freshly-set-up app built and signed successfully but failed at the end on a `.gitignore` conflict trying to `git add` the generated `.xcodeproj`. Inspecting the working tree beforehand showed real damage already done: `CFBundleVersion` had been hardcoded as a literal number directly into the tracked `Info.plist`, replacing the `$(CURRENT_PROJECT_VERSION)` variable substitution. Meanwhile the actual build-number bump had gone into the gitignored `.xcodeproj`'s build settings — invisible to git and silently discarded by the next `xcodegen generate`.

**Root cause:** `increment_build_number(xcodeproj:)` and `commit_version_bump` are fastlane actions designed around a workflow where the `.xcodeproj` is committed and is the single source of truth for the build number. This template's whole premise — XcodeGen generates the `.xcodeproj` from `project.yml`, and the generated project is gitignored per `_setup/guides/02-xcode-project.md` — is fundamentally incompatible with that assumption. The `beta` and `release` lanes in the template's own `fastlane/Fastfile` shipped this exact pattern, so every app generated from the template inherited the bug. (Filed as issue #3.)

**Fix applied:** Replaced `increment_build_number(xcodeproj:)` + `commit_version_bump` in both `beta` and `release` (and in `_setup/guides/07-fastlane.md` and `08-testflight.md`'s matching examples) with a plain `current_build = latest_testflight_build_number(...); next_build = current_build + 1`, passed to `build_app` via `xcargs: "CURRENT_PROJECT_VERSION=#{next_build}"`. This touches neither the tracked `Info.plist` nor the gitignored `.xcodeproj`, so there's nothing to commit afterward and nothing for `xcodegen generate` to discard. Also updated `_setup/CLAUDE.md` and `_setup/CHECKLIST.md`, which previously instructed manually bumping `CURRENT_PROJECT_VERSION` in `project.yml` before a TestFlight upload — a step this fix makes a no-op, since `build_app`'s `xcargs` now overrides whatever `project.yml` says.

**Suggested template improvement:** Nothing currently prevents `increment_build_number`/`commit_version_bump` from being reintroduced by a future edit. A CI check (e.g. a `grep -q` guard in `.github/workflows/ci.yml`) that fails the build if either appears in `fastlane/Fastfile` would catch a regression before it ships. Separately, `latest_testflight_build_number` has no `initial_build_number:` fallback and defaults to treating a build-less app as build `1`, so the very first `fastlane beta` on a brand-new app ships as build `2` (skipping build 1) rather than matching `project.yml`'s declared `CURRENT_PROJECT_VERSION: "1"`; harmless but worth a one-line callout in `07-fastlane.md` if it causes confusion.

---

## 13. `rename.sh` doesn't generate a placeholder app icon

**Symptom:** A developer who runs `_setup/scripts/rename.sh` directly instead of the interactive `init.sh` wizard gets a correctly-declared `AppIcon.appiconset` slot with no backing image. This isn't caught locally — Xcode builds and runs fine in the simulator — and only surfaces at the first TestFlight upload, which fails with "Missing required icon file. The bundle does not contain an app icon for iPad of exactly '152x152' pixels..." and "Missing Info.plist value... CFBundleIconName... is missing."

**Root cause:** Placeholder icon generation (`Icon-1024.png`) is a step inside `init.sh`'s interactive wizard only. `rename.sh` — a documented, valid standalone entry point for a developer who already knows their target values — never calls it, so nothing warns that the icon is missing until Apple's server-side validation catches it, potentially days into setup.

**Fix applied:** Documented the gap in `_setup/guides/12-app-icons-screenshots.md`, right after the "Adding to the Project" steps, so anyone using `rename.sh` directly is told to generate or add a placeholder icon before their first `fastlane beta`/`release`.

**Suggested template improvement:** `rename.sh` could check for and generate a placeholder `Icon-1024.png` itself (or at least print a warning) when one doesn't already exist, rather than relying on developers to have read this note.

---

## 14. `cleanup.sh` conflated the Xcode target name and display name into one variable

**Symptom:** Two bugs traced to the same root cause. First, the rewritten `README.md` told the user to `Open App/$APP_DISPLAY_NAME.xcodeproj`, but XcodeGen always names the generated project after `project.yml`'s `name:` field (the target name, e.g. `WeatherNow`), never `PRODUCT_NAME` (e.g. `Weather Now`) — whenever the display name contains a space, the README pointed at a `.xcodeproj` path that doesn't exist. Second, the single-line `grep -m1 'PRODUCT_NAME' project.yml` used to derive that value was fragile: if `PRODUCT_NAME` wasn't present as a plain single-line value for any reason, the grep could match an unrelated comment line instead, and since that line had no literal `PRODUCT_NAME:` to strip, the whole matched line — comment and all — got written as the README's title.

**Root cause:** `cleanup.sh` derived both the target name and the display name from one fragile grep against a single field, treating two genuinely different values (`name:` vs. `PRODUCT_NAME:` in `project.yml`) as interchangeable. (Filed as issue #4.)

**Fix applied:** Derive the two names independently from two reliable sources: `APP_TARGET_NAME` from `project.yml`'s top-level `name:` field (used for the `.xcodeproj` path), and `APP_DISPLAY_NAME` from `Info.plist`'s `CFBundleDisplayName` (used for the README title), located dynamically via `find` since its parent directory varies per app. Verified against both this repo's own unmodified placeholder files and a simulated renamed app (`AppNameHere` / `App Name Here`), confirming the `.xcodeproj` path now actually exists and no comment lines leak into the README.

**Suggested template improvement:** A basic shellcheck/bats test for `cleanup.sh` against a fixture `project.yml` + `Info.plist` would catch this class of regression before it reaches a real app's cleanup run.
