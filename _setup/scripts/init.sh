#!/usr/bin/env bash
# init.sh — Interactive setup wizard for the app template
#
# Run this once after cloning the template:
#   chmod +x _setup/scripts/init.sh
#   ./_setup/scripts/init.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RENAME_SCRIPT="$REPO_ROOT/_setup/scripts/rename.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

print_header() {
  echo ""
  echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}${BOLD}║        iOS App Template Setup            ║${NC}"
  echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

prompt() {
  local var_name="$1"
  local prompt_text="$2"
  local default_value="${3:-}"
  local value=""

  if [ -n "$default_value" ]; then
    echo -ne "${CYAN}$prompt_text${NC} ${YELLOW}[$default_value]${NC}: "
  else
    echo -ne "${CYAN}$prompt_text${NC}: "
  fi

  read -r value

  if [ -z "$value" ] && [ -n "$default_value" ]; then
    value="$default_value"
  fi

  while [ -z "$value" ]; do
    echo -e "${RED}This field is required.${NC}"
    echo -ne "${CYAN}$prompt_text${NC}: "
    read -r value
  done

  eval "$var_name=\"$value\""
}

confirm() {
  local prompt_text="$1"
  local response
  echo -ne "${YELLOW}$prompt_text [y/N]${NC}: "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

check_tool() {
  local tool="$1"
  if command -v "$tool" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $tool"
    return 0
  else
    echo -e "  ${RED}✗${NC} $tool (not found)"
    return 1
  fi
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

print_header

echo -e "${BOLD}Step 1: Checking prerequisites...${NC}"
echo ""

MISSING=0
check_tool xcodegen || MISSING=1
check_tool swiftformat || MISSING=1
check_tool swiftlint || MISSING=1
check_tool fastlane || MISSING=1
check_tool bundle || MISSING=1

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo -e "${YELLOW}Some tools are missing. See _setup/guides/00-prerequisites.md for install instructions.${NC}"
  if ! confirm "Continue anyway?"; then
    exit 1
  fi
fi

echo ""
echo -e "${BOLD}Step 2: App information${NC}"
echo -e "${YELLOW}These values will replace all __PLACEHOLDER__ tokens in the template.${NC}"
echo ""

# App Name (PascalCase)
while true; do
  prompt APP_NAME "App name (PascalCase, no spaces — e.g. WeatherNow)"
  # Validate: no spaces, no special chars except letters/digits
  if [[ "$APP_NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
    break
  else
    echo -e "${RED}Invalid: must start with a letter, contain only letters and digits, no spaces.${NC}"
  fi
done

# Display Name (human-readable)
prompt APP_DISPLAY_NAME "Display name (shown on device — e.g. Weather Now)" "$APP_NAME"

# Bundle ID
SUGGESTED_BUNDLE="com.$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"
while true; do
  prompt BUNDLE_ID "Bundle ID (reverse-DNS — e.g. com.yourname.appname)" "$SUGGESTED_BUNDLE"
  if [[ "$BUNDLE_ID" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$ ]]; then
    break
  else
    echo -e "${RED}Invalid bundle ID. Use lowercase reverse-DNS format: com.yourname.appname${NC}"
  fi
done

# Org Identifier (everything before the last segment)
ORG_IDENTIFIER="${BUNDLE_ID%.*}"

# Team ID
while true; do
  prompt TEAM_ID "Apple Developer Team ID (10 chars — found at developer.apple.com → Membership)"
  if [[ "${#TEAM_ID}" -eq 10 ]] && [[ "$TEAM_ID" =~ ^[A-Z0-9]+$ ]]; then
    break
  else
    echo -e "${RED}Team ID must be exactly 10 uppercase alphanumeric characters.${NC}"
  fi
done

# Apple ID
prompt APPLE_ID "Apple ID email (used for App Store Connect)"

# Match repo
prompt MATCH_REPO "SSH URL for fastlane match certs repo (private git repo — e.g. git@github.com:yourorg/certs.git)"

# Year
CURRENT_YEAR=$(date +%Y)
YEAR="$CURRENT_YEAR"

echo ""
echo -e "${BOLD}Step 3: Summary${NC}"
echo ""
echo -e "  App Name:        ${GREEN}$APP_NAME${NC}"
echo -e "  Display Name:    ${GREEN}$APP_DISPLAY_NAME${NC}"
echo -e "  Bundle ID:       ${GREEN}$BUNDLE_ID${NC}"
echo -e "  Org Identifier:  ${GREEN}$ORG_IDENTIFIER${NC}"
echo -e "  Team ID:         ${GREEN}$TEAM_ID${NC}"
echo -e "  Apple ID:        ${GREEN}$APPLE_ID${NC}"
echo -e "  Match Repo:      ${GREEN}$MATCH_REPO${NC}"
echo -e "  Year:            ${GREEN}$YEAR${NC}"
echo ""

if ! confirm "Replace all placeholders with these values?"; then
  echo "Aborted. No changes made."
  exit 0
fi

echo ""
echo -e "${BOLD}Step 4: Replacing placeholders...${NC}"

chmod +x "$RENAME_SCRIPT"
"$RENAME_SCRIPT" \
  "__APP_NAME__=$APP_NAME" \
  "__APP_DISPLAY_NAME__=$APP_DISPLAY_NAME" \
  "__BUNDLE_ID__=$BUNDLE_ID" \
  "__ORG_IDENTIFIER__=$ORG_IDENTIFIER" \
  "__TEAM_ID__=$TEAM_ID" \
  "__APPLE_ID__=$APPLE_ID" \
  "__MATCH_REPO__=$MATCH_REPO" \
  "__YEAR__=$YEAR"

echo ""
echo -e "${BOLD}Step 5: Generating Xcode project...${NC}"

cd "$REPO_ROOT/App"
xcodegen generate
cd "$REPO_ROOT"

echo ""
echo -e "${BOLD}Step 6: Installing Ruby gems...${NC}"
bundle install

echo ""
echo -e "${GREEN}${BOLD}✓ Template initialized successfully!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. ${CYAN}Open the project:${NC}"
echo -e "     open App/$APP_NAME.xcodeproj"
echo ""
echo -e "  2. ${CYAN}Complete Apple Developer setup (if not done):${NC}"
echo -e "     See _setup/guides/01-apple-dev-program.md"
echo ""
echo -e "  3. ${CYAN}Set up code signing:${NC}"
echo -e "     bundle exec fastlane match development"
echo -e "     bundle exec fastlane match appstore"
echo ""
echo -e "  4. ${CYAN}Work through the checklist:${NC}"
echo -e "     open _setup/CHECKLIST.md"
echo ""
echo -e "${YELLOW}Tip: Add App/$APP_NAME.xcodeproj to your .gitignore (it's already there).${NC}"
echo -e "${YELLOW}The project is generated from App/project.yml — commit that instead.${NC}"
echo ""
