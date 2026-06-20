#!/usr/bin/env bash
# init.sh — Interactive setup wizard for the iOS app template
#
# What this script does:
#   1. Checks prerequisites (Xcode, XcodeGen, fastlane, gh CLI, etc.)
#   2. Sets up the GitHub repository (creates one or uses existing)
#   3. Collects app information (name, bundle ID, team ID, etc.)
#   4. Creates a private GitHub repo for fastlane match certs (or uses existing)
#   5. Computes GitHub Pages URLs for support and privacy pages
#   6. Replaces all __PLACEHOLDER__ tokens throughout the project
#   7. Generates the Xcode project from project.yml
#   8. Generates a placeholder app icon (if ImageMagick is available)
#   9. Copies fastlane/.env.template → fastlane/.env and pre-fills known values
#  10. Installs Ruby gems (fastlane)
#  11. Enables GitHub Pages for the docs/ folder
#
# Run once after cloning or using this template:
#   chmod +x _setup/scripts/init.sh
#   ./_setup/scripts/init.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RENAME_SCRIPT="$REPO_ROOT/_setup/scripts/rename.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}${BOLD}║       iOS App Template — Init Wizard         ║${NC}"
  echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════╝${NC}"
  echo ""
}

step() { echo ""; echo -e "${BOLD}── $1 ──${NC}"; echo ""; }

info()    { echo -e "  ${CYAN}→${NC} $1"; }
success() { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $1"; }
err()     { echo -e "  ${RED}✗${NC} $1"; }

prompt() {
  local var_name="$1" prompt_text="$2" default="${3:-}" val=""
  if [ -n "$default" ]; then
    echo -ne "  ${CYAN}$prompt_text${NC} ${YELLOW}[$default]${NC}: "
  else
    echo -ne "  ${CYAN}$prompt_text${NC}: "
  fi
  read -r val
  [ -z "$val" ] && val="$default"
  while [ -z "$val" ]; do
    echo -e "  ${RED}Required.${NC}"
    echo -ne "  ${CYAN}$prompt_text${NC}: "
    read -r val
  done
  eval "$var_name=\"$val\""
}

confirm() {
  local response
  echo -ne "  ${YELLOW}$1 [y/N]${NC}: "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

check_tool() {
  if command -v "$1" &>/dev/null; then success "$1 $(command -v "$1")"; return 0
  else err "$1 — not found"; return 1; fi
}

# Extract GitHub username and repo name from a remote URL
# Supports: git@github.com:user/repo.git  and  https://github.com/user/repo.git
parse_github_url() {
  local url="$1"
  if [[ "$url" =~ github\.com[:/]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
    GH_USERNAME="${BASH_REMATCH[1]}"
    APP_REPO_NAME="${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Step 0 — Prerequisites
# ─────────────────────────────────────────────────────────────────────────────
print_header
step "Step 0: Checking prerequisites"

MISSING=0
check_tool xcodegen     || MISSING=1
check_tool swiftformat  || MISSING=1
check_tool swiftlint    || MISSING=1
check_tool fastlane     || MISSING=1
check_tool bundle       || MISSING=1
check_tool git          || MISSING=1

# gh CLI — optional but enables automatic repo creation and Pages enablement
HAS_GH=0
if check_tool gh; then
  HAS_GH=1
else
  warn "GitHub CLI (gh) not found. Install with: brew install gh"
  warn "Without it, you'll create repos manually on github.com."
fi

if [ "$MISSING" -eq 1 ]; then
  echo ""
  warn "Some required tools are missing."
  warn "See _setup/guides/00-prerequisites.md for install instructions."
  if ! confirm "Continue anyway?"; then exit 1; fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 1 — GitHub repository
# ─────────────────────────────────────────────────────────────────────────────
step "Step 1: GitHub repository"

GH_USERNAME=""
APP_REPO_NAME=""
PAGES_BASE=""

REMOTE_URL=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "")

if [ -n "$REMOTE_URL" ]; then
  info "Current git remote: $REMOTE_URL"
  if parse_github_url "$REMOTE_URL"; then
    success "GitHub user/org: $GH_USERNAME"
    success "Repo name:       $APP_REPO_NAME"
    PAGES_BASE="https://$GH_USERNAME.github.io/$APP_REPO_NAME"
    info "GitHub Pages will be at: $PAGES_BASE/"
  else
    warn "Remote doesn't look like a GitHub URL — GitHub Pages URLs will need to be set manually."
    prompt GH_USERNAME "GitHub username or org (for Pages URLs)"
    prompt APP_REPO_NAME "GitHub repo name/slug"
    PAGES_BASE="https://$GH_USERNAME.github.io/$APP_REPO_NAME"
  fi
else
  info "No git remote configured."
  if [ "$HAS_GH" -eq 1 ] && confirm "Create a new GitHub repo for this app now?"; then
    prompt GH_USERNAME "GitHub username or organization"
    prompt APP_REPO_NAME "Repository name (slug, e.g. my-great-app)"
    echo ""
    warn "GitHub Pages is free for public repos. Private repos require GitHub Pro (\$4/mo)."
    VISIBILITY="public"
    if ! confirm "Make the repo public? (recommended for free GitHub Pages)"; then
      VISIBILITY="private"
      warn "GitHub Pages will not work on a free plan with a private repo."
    fi
    echo ""
    info "Creating $VISIBILITY repo: $GH_USERNAME/$APP_REPO_NAME..."
    gh repo create "$GH_USERNAME/$APP_REPO_NAME" \
      --"$VISIBILITY" \
      --source="$REPO_ROOT" \
      --remote=origin \
      --push 2>/dev/null || {
        # Repo may already exist — just set the remote
        git -C "$REPO_ROOT" remote add origin "git@github.com:$GH_USERNAME/$APP_REPO_NAME.git" 2>/dev/null || \
        git -C "$REPO_ROOT" remote set-url origin "git@github.com:$GH_USERNAME/$APP_REPO_NAME.git"
    }
    success "Repo created: github.com/$GH_USERNAME/$APP_REPO_NAME"
    PAGES_BASE="https://$GH_USERNAME.github.io/$APP_REPO_NAME"
  else
    info "Skipping GitHub repo creation."
    prompt GH_USERNAME "GitHub username or org (for Pages URLs — enter to skip)" ""
    if [ -n "$GH_USERNAME" ]; then
      prompt APP_REPO_NAME "GitHub repo name/slug" ""
      [ -n "$APP_REPO_NAME" ] && PAGES_BASE="https://$GH_USERNAME.github.io/$APP_REPO_NAME"
    fi
  fi
fi

SUPPORT_URL="${PAGES_BASE:+$PAGES_BASE/support}"
PRIVACY_URL="${PAGES_BASE:+$PAGES_BASE/privacy}"

# ─────────────────────────────────────────────────────────────────────────────
# Step 2 — App information
# ─────────────────────────────────────────────────────────────────────────────
step "Step 2: App information"

info "These values fill in all __PLACEHOLDER__ tokens in the project."
echo ""

# App name
while true; do
  prompt APP_NAME "App name — PascalCase, no spaces (e.g. WeatherNow)"
  [[ "$APP_NAME" =~ ^[A-Za-z][A-Za-z0-9]+$ ]] && break
  err "Must start with a letter, letters and digits only, no spaces."
done

# First letter (for placeholder icon)
APP_NAME_INITIAL="${APP_NAME:0:1}"

# Display name
prompt APP_DISPLAY_NAME "Display name — shown on device (e.g. Weather Now)" "$APP_NAME"

# Bundle ID
SUGGESTED_BUNDLE="com.$(echo "${GH_USERNAME:-yourname}" | tr '[:upper:]' '[:lower:]').$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"
while true; do
  prompt BUNDLE_ID "Bundle ID — reverse-DNS (e.g. com.yourname.weathernow)" "$SUGGESTED_BUNDLE"
  [[ "$BUNDLE_ID" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$ ]] && break
  err "Use lowercase reverse-DNS: com.yourname.appname"
done
ORG_IDENTIFIER="${BUNDLE_ID%.*}"

# Team ID
while true; do
  prompt TEAM_ID "Apple Developer Team ID — 10 chars (developer.apple.com → Membership)"
  [[ "${#TEAM_ID}" -eq 10 && "$TEAM_ID" =~ ^[A-Z0-9]+$ ]] && break
  err "Must be exactly 10 uppercase alphanumeric characters."
done

# Apple ID
prompt APPLE_ID "Apple ID email (App Store Connect)"

# Contact email for support/privacy pages
prompt CONTACT_EMAIL "Support contact email (shown on the support page)" "$APPLE_ID"

CURRENT_YEAR=$(date +%Y)

# ─────────────────────────────────────────────────────────────────────────────
# Step 3 — fastlane match certs repo
# ─────────────────────────────────────────────────────────────────────────────
step "Step 3: fastlane match — certificates repo"

info "match stores your signing certificates in a private git repo."
info "This repo must be private and separate from your app repo."
echo ""

MATCH_REPO=""

if confirm "Do you already have a private certs repo for match?"; then
  prompt MATCH_REPO "SSH URL of your existing certs repo (e.g. git@github.com:yourorg/certs.git)"
else
  if [ "$HAS_GH" -eq 1 ] && confirm "Create a new private certs repo on GitHub now?"; then
    CERTS_REPO_NAME="${APP_NAME}-certs"
    prompt CERTS_REPO_NAME "Certs repo name" "$CERTS_REPO_NAME"
    info "Creating private repo: $GH_USERNAME/$CERTS_REPO_NAME..."
    gh repo create "$GH_USERNAME/$CERTS_REPO_NAME" \
      --private \
      --description "fastlane match certs for $APP_DISPLAY_NAME" \
      2>/dev/null && success "Created: github.com/$GH_USERNAME/$CERTS_REPO_NAME"
    MATCH_REPO="git@github.com:$GH_USERNAME/$CERTS_REPO_NAME.git"
    success "Match repo: $MATCH_REPO"
  else
    warn "Skipping match repo creation."
    warn "Create a private GitHub repo manually, then run: bundle exec fastlane match init"
    prompt MATCH_REPO "SSH URL of your certs repo (or leave blank to fill in later)" ""
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 4 — GitHub Pages URLs
# ─────────────────────────────────────────────────────────────────────────────
step "Step 4: GitHub Pages URLs"

if [ -n "$PAGES_BASE" ]; then
  success "Support URL:  $SUPPORT_URL"
  success "Privacy URL:  $PRIVACY_URL"
  info "These will be filled into docs/ HTML files and fastlane/Deliverfile."
else
  warn "GitHub Pages base URL not set. Using placeholder values."
  warn "Update docs/ HTML and fastlane/Deliverfile manually after setting up Pages."
  SUPPORT_URL="https://example.com/support"
  PRIVACY_URL="https://example.com/privacy"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 5 — Summary + confirm
# ─────────────────────────────────────────────────────────────────────────────
step "Step 5: Summary"

echo -e "  App Name:         ${GREEN}$APP_NAME${NC}"
echo -e "  Display Name:     ${GREEN}$APP_DISPLAY_NAME${NC}"
echo -e "  Bundle ID:        ${GREEN}$BUNDLE_ID${NC}"
echo -e "  Org Identifier:   ${GREEN}$ORG_IDENTIFIER${NC}"
echo -e "  Team ID:          ${GREEN}$TEAM_ID${NC}"
echo -e "  Apple ID:         ${GREEN}$APPLE_ID${NC}"
echo -e "  Contact Email:    ${GREEN}$CONTACT_EMAIL${NC}"
echo -e "  Match Repo:       ${GREEN}${MATCH_REPO:-'(not set)'}${NC}"
echo -e "  GitHub User/Org:  ${GREEN}${GH_USERNAME:-'(not set)'}${NC}"
echo -e "  GitHub Repo:      ${GREEN}${APP_REPO_NAME:-'(not set)'}${NC}"
echo -e "  Support URL:      ${GREEN}$SUPPORT_URL${NC}"
echo -e "  Privacy URL:      ${GREEN}$PRIVACY_URL${NC}"
echo -e "  Year:             ${GREEN}$CURRENT_YEAR${NC}"
echo ""

if ! confirm "Replace all placeholders with these values and continue?"; then
  echo "Aborted. No changes made."
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 6 — Replace placeholders
# ─────────────────────────────────────────────────────────────────────────────
step "Step 6: Replacing placeholders"

chmod +x "$RENAME_SCRIPT"
"$RENAME_SCRIPT" \
  "__APP_NAME__=$APP_NAME" \
  "__APP_DISPLAY_NAME__=$APP_DISPLAY_NAME" \
  "__APP_NAME_INITIAL__=$APP_NAME_INITIAL" \
  "__BUNDLE_ID__=$BUNDLE_ID" \
  "__ORG_IDENTIFIER__=$ORG_IDENTIFIER" \
  "__TEAM_ID__=$TEAM_ID" \
  "__YEAR__=$CURRENT_YEAR" \
  "__SUPPORT_URL__=$SUPPORT_URL" \
  "__PRIVACY_URL__=$PRIVACY_URL" \
  "__CONTACT_EMAIL__=$CONTACT_EMAIL" \
  "__GH_USERNAME__=${GH_USERNAME:-}" \
  "__APP_REPO_NAME__=${APP_REPO_NAME:-}" \
  "__PRIVACY_LAST_UPDATED__=$(date '+%B %d, %Y')" \
  "__DEVELOPER_NAME__=${GH_USERNAME:-Your Name}" \
  "__APP_STORE_URL__=https://apps.apple.com" \
  "__APP_VERSION__=1.0.0"

# Note: APPLE_ID and MATCH_GIT_URL are intentionally NOT replaced in files —
# they go into fastlane/.env only (see Step 9). __TEAM_ID__ IS replaced here
# because XcodeGen requires it in project.yml at project-generation time.

# ─────────────────────────────────────────────────────────────────────────────
# Step 7 — Generate Xcode project
# ─────────────────────────────────────────────────────────────────────────────
step "Step 7: Generating Xcode project"

cd "$REPO_ROOT/App"
xcodegen generate && success "Generated App/$APP_NAME.xcodeproj"
cd "$REPO_ROOT"

# ─────────────────────────────────────────────────────────────────────────────
# Step 8 — Placeholder app icon
# ─────────────────────────────────────────────────────────────────────────────
step "Step 8: Placeholder app icon"

ICON_DIR="$REPO_ROOT/App/Sources/$APP_NAME/Resources/Assets.xcassets/AppIcon.appiconset"
ICON_PATH="$ICON_DIR/Icon-1024.png"

if command -v convert &>/dev/null; then
  info "Generating placeholder icon with the letter '$APP_NAME_INITIAL'..."
  mkdir -p "$ICON_DIR"
  convert -size 1024x1024 \
    "gradient:#007AFF-#5856D6" \
    -gravity center \
    -font Helvetica \
    -pointsize 500 \
    -fill white \
    -annotate +0+30 "$APP_NAME_INITIAL" \
    "$ICON_PATH" 2>/dev/null && success "Icon saved to $ICON_PATH"
  warn "Replace Icon-1024.png with your real icon before App Store submission."
else
  warn "ImageMagick not found — skipping placeholder icon generation."
  warn "Add a 1024×1024 PNG (no alpha, no rounded corners) to:"
  warn "  $ICON_PATH"
  warn "Install ImageMagick with: brew install imagemagick"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 9 — Set up fastlane/.env from template
# ─────────────────────────────────────────────────────────────────────────────
step "Step 9: Setting up fastlane/.env"

ENV_TEMPLATE="$REPO_ROOT/fastlane/.env.template"
ENV_FILE="$REPO_ROOT/fastlane/.env"

if [ -f "$ENV_FILE" ]; then
  if ! confirm "fastlane/.env already exists. Overwrite it?"; then
    info "Keeping existing fastlane/.env"
  else
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    info "Copied .env.template → .env"
  fi
else
  cp "$ENV_TEMPLATE" "$ENV_FILE"
  info "Copied .env.template → .env"
fi

# Pre-fill known non-secret values into .env
sed -i '' "s|^APPLE_ID=.*|APPLE_ID=$APPLE_ID|" "$ENV_FILE"
sed -i '' "s|^APPLE_TEAM_ID=.*|APPLE_TEAM_ID=$TEAM_ID|" "$ENV_FILE"
[ -n "$MATCH_REPO" ] && sed -i '' "s|^MATCH_GIT_URL=.*|MATCH_GIT_URL=$MATCH_REPO|" "$ENV_FILE"

success "Pre-filled APPLE_ID, APPLE_TEAM_ID${MATCH_REPO:+, MATCH_GIT_URL} in fastlane/.env"
echo ""
warn "You still need to fill in these values in fastlane/.env:"
warn "  MATCH_PASSWORD                      — passphrase to encrypt the certs repo"
warn "  APP_STORE_CONNECT_API_KEY_ID        — from App Store Connect → Integrations"
warn "  APP_STORE_CONNECT_API_KEY_ISSUER_ID — from App Store Connect → Integrations"
warn "  APP_STORE_CONNECT_API_KEY_PATH      — path to your downloaded .p8 file"
echo ""
info "Open fastlane/.env to fill in the remaining values:"
info "  \$EDITOR fastlane/.env"

# ─────────────────────────────────────────────────────────────────────────────
# Step 10 — Install Ruby gems
# ─────────────────────────────────────────────────────────────────────────────
step "Step 10: Installing Ruby gems"

if [ -f "$REPO_ROOT/Gemfile" ]; then
  cd "$REPO_ROOT"
  bundle install --quiet && success "Gems installed"
else
  warn "Gemfile not found — skipping gem install"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 11 — Enable GitHub Pages
# ─────────────────────────────────────────────────────────────────────────────
step "Step 11: GitHub Pages"

if [ -n "$PAGES_BASE" ] && [ "$HAS_GH" -eq 1 ] && [ -n "$GH_USERNAME" ] && [ -n "$APP_REPO_NAME" ]; then
  info "Enabling GitHub Pages for docs/ folder on main branch..."
  gh api "repos/$GH_USERNAME/$APP_REPO_NAME/pages" \
    --method POST \
    -f source='{"branch":"main","path":"/docs"}' \
    --silent 2>/dev/null \
    && success "GitHub Pages enabled: $PAGES_BASE" \
    || warn "Pages may already be enabled, or the repo needs to be pushed first."
  info "It may take 1–5 minutes for the pages to go live."
else
  warn "Skipping automatic Pages setup (gh CLI not available or repo not on GitHub)."
  info "To enable manually:"
  info "  1. Go to github.com/$GH_USERNAME/$APP_REPO_NAME → Settings → Pages"
  info "  2. Source: Deploy from branch · Branch: main · Folder: /docs"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Template initialized successfully!${NC}"
echo ""
echo -e "${BOLD}Open the project:${NC}"
echo -e "  open App/$APP_NAME.xcodeproj"
echo ""
echo -e "${BOLD}Fill in remaining secrets:${NC}"
echo -e "  \$EDITOR fastlane/.env"
echo ""
echo -e "${BOLD}Set up code signing (after filling in .env):${NC}"
echo -e "  bundle exec fastlane match development"
echo -e "  bundle exec fastlane match appstore"
echo ""
echo -e "${BOLD}Work through the checklist:${NC}"
echo -e "  open _setup/CHECKLIST.md"
echo ""
if [ -n "$SUPPORT_URL" ]; then
  echo -e "${BOLD}Your App Store URLs:${NC}"
  echo -e "  Support:  $SUPPORT_URL"
  echo -e "  Privacy:  $PRIVACY_URL"
  echo ""
fi
