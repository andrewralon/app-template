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
