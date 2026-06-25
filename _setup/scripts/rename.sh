#!/usr/bin/env bash
# rename.sh — Replace all __PLACEHOLDER__ tokens in the template
#
# Compatible with bash 3.2+ (macOS default). No bash 4 features used.
#
# Usage: rename.sh "KEY=VALUE" "KEY2=VALUE2" ...
# Example:
#   rename.sh \
#     "__APP_NAME__=WeatherNow" \
#     "__APP_DISPLAY_NAME__=Weather Now" \
#     "__BUNDLE_ID__=com.acme.weathernow" \
#     "__ORG_IDENTIFIER__=com.acme" \
#     "__TEAM_ID__=ABCD123456" \
#     "__YEAR__=2026"
#
# Note: APPLE_ID and MATCH_GIT_URL are NOT file placeholders — they go in
# fastlane/.env only and are never committed to the repo.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
THIS_SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# --- Parse key=value arguments into parallel arrays (bash 3.2 compatible) ---
keys_arr=()
vals_arr=()
app_name_value=""

for arg in "$@"; do
  key="${arg%%=*}"
  value="${arg#*=}"
  keys_arr+=("$key")
  vals_arr+=("$value")
  if [ "$key" = "__APP_NAME__" ]; then
    app_name_value="$value"
  fi
done

if [ ${#keys_arr[@]} -eq 0 ]; then
  echo "Error: No replacements provided."
  echo "Usage: $0 \"__KEY__=value\" ..."
  exit 1
fi

# --- Use git mv when inside a git repo so renames appear in history ---
in_git_repo=0
git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1 && in_git_repo=1

git_mv() {
  if [ $in_git_repo -eq 1 ]; then
    git -C "$REPO_ROOT" mv "$1" "$2"
  else
    mv "$1" "$2"
  fi
}

echo "Repo root: $REPO_ROOT"
echo "Replacements:"
for i in "${!keys_arr[@]}"; do
  echo "  ${keys_arr[$i]} → ${vals_arr[$i]}"
done
echo ""

# --- File extensions to process ---
EXTENSIONS=("swift" "yml" "yaml" "md" "plist" "rb" "sh" "json" "txt" "xcconfig" "strings" "html" "css" "js")

# --- Extensionless fastlane files to process by name ---
NAMED_FILES=("Fastfile" "Appfile" "Matchfile" "Deliverfile" "Snapfile" "Gymfile" "Scanfile" "Screenshotfile")

# --- Build find arguments without a trailing -o ---
FIND_ARGS=()
first=1
for ext in "${EXTENSIONS[@]}"; do
  if [ $first -eq 0 ]; then
    FIND_ARGS+=("-o")
  fi
  FIND_ARGS+=("-name" "*.${ext}")
  first=0
done
for name in "${NAMED_FILES[@]}"; do
  FIND_ARGS+=("-o" "-name" "$name")
done

# --- Perform replacements in file contents ---
echo "Replacing in file contents..."
while IFS= read -r -d '' file; do
  # Never modify this script itself
  [ "$file" = "$THIS_SCRIPT" ] && continue
  modified=0
  for i in "${!keys_arr[@]}"; do
    key="${keys_arr[$i]}"
    value="${vals_arr[$i]}"
    # Escape special sed characters in value
    escaped_value=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')
    if grep -qF "$key" "$file" 2>/dev/null; then
      sed -i '' "s|${key}|${escaped_value}|g" "$file"
      modified=1
    fi
  done
  [ $modified -eq 1 ] && echo "  Updated: $file"
done < <(find "$REPO_ROOT" \
  -not -path "*/\.*" \
  -not -path "*/_build/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/_setup/*" \
  -not -name "CLAUDE.md" \
  -type f \
  \( "${FIND_ARGS[@]}" \) \
  -print0)

# --- Rename directories ---
echo ""
echo "Renaming directories..."
if [ -n "$app_name_value" ]; then
  while IFS= read -r dir; do
    parent="$(dirname "$dir")"
    base="$(basename "$dir")"
    new_base="${base//__APP_NAME__/$app_name_value}"
    if [ "$base" != "$new_base" ]; then
      git_mv "$dir" "$parent/$new_base"
      echo "  Renamed dir: $dir → $parent/$new_base"
    fi
  done < <(find "$REPO_ROOT/App" -depth -type d -name "*__APP_NAME__*" 2>/dev/null | sort -r)
fi

# --- Rename files ---
echo ""
echo "Renaming files..."
if [ -n "$app_name_value" ]; then
  while IFS= read -r file; do
    parent="$(dirname "$file")"
    base="$(basename "$file")"
    new_base="${base//__APP_NAME__/$app_name_value}"
    if [ "$base" != "$new_base" ]; then
      git_mv "$file" "$parent/$new_base"
      echo "  Renamed file: $file → $parent/$new_base"
    fi
  done < <(find "$REPO_ROOT/App" -type f -name "*__APP_NAME__*" 2>/dev/null)
fi

echo ""
echo "Done! All placeholders replaced."
echo ""
echo "Next steps:"
echo "  1. cd App && xcodegen generate"
echo "  2. open App/${app_name_value:-__APP_NAME__}.xcodeproj"
echo ""
echo "Note: APPLE_ID and MATCH_GIT_URL are not file placeholders — they belong"
echo "      in fastlane/.env only and are pre-filled there by init.sh."
