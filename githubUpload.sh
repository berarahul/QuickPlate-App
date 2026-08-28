#!/bin/bash

# Exit immediately if any command fails
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m'

echo -e "${BLUE}=== QuickPlate GitHub Release Uploader ===${CLEAR}"

# 1. Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}Error: pubspec.yaml not found in the current directory.${CLEAR}"
  exit 1
fi

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version:[[:space:]]*//g')
TAG_NAME="v$CURRENT_VERSION"

echo -e "Target App Version: ${GREEN}${CURRENT_VERSION}${CLEAR} (Tag: ${GREEN}${TAG_NAME}${CLEAR})"

# 2. Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
  echo -e "${RED}Error: GitHub CLI (gh) is not installed.${CLEAR}"
  echo -e "Please install it via: sudo apt install gh OR https://cli.github.com"
  exit 1
fi

# 3. Check GitHub CLI authentication status
if ! gh auth status &> /dev/null; then
  echo -e "${YELLOW}Warning: You are not logged into GitHub CLI.${CLEAR}"
  echo -e "Please run '${GREEN}gh auth login${CLEAR}' to authenticate with GitHub."
  exit 1
fi

# 4. Prompt user for Release Notes / What's New
echo -e "\n${YELLOW}What's new in this release? (Enter release notes/description):${CLEAR}"
read -p "> " RELEASE_NOTES

if [ -z "$RELEASE_NOTES" ]; then
  RELEASE_NOTES="QuickPlate App Release ${CURRENT_VERSION} with Shorebird CodePush enabled."
fi

# 5. Locate Shorebird-enabled APK
echo -e "\n${BLUE}Locating Shorebird-enabled release APK...${CLEAR}"
APK_SOURCE=""

if [ -f "quickplate-release.apk" ]; then
  APK_SOURCE="quickplate-release.apk"
elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
elif [ -f "build/app/outputs/apk/release/app-release.apk" ]; then
  APK_SOURCE="build/app/outputs/apk/release/app-release.apk"
else
  APK_SOURCE=$(find build/app/outputs/ -name "*.apk" 2>/dev/null | head -n 1)
fi

if [ -z "$APK_SOURCE" ] || [ ! -f "$APK_SOURCE" ]; then
  echo -e "${RED}Error: Shorebird-enabled APK file not found!${CLEAR}"
  echo -e "${YELLOW}Please run './release.sh' first to build and publish the Shorebird release.${CLEAR}"
  exit 1
fi

# Copy to quickplate-release.apk
cp "$APK_SOURCE" "quickplate-release.apk"
echo -e "${GREEN}Prepared artifact: quickplate-release.apk${CLEAR}"

# 6. Publish / Upload Release to GitHub
echo -e "\n${BLUE}Publishing release artifact to GitHub Releases...${CLEAR}"

# Check if release tag already exists on GitHub
if gh release view "$TAG_NAME" &> /dev/null; then
  echo -e "${YELLOW}Release ${TAG_NAME} already exists. Uploading quickplate-release.apk asset...${CLEAR}"
  gh release upload "$TAG_NAME" "quickplate-release.apk" --clobber
  gh release edit "$TAG_NAME" --notes "$RELEASE_NOTES" --title "QuickPlate Release $TAG_NAME"
else
  echo -e "Creating GitHub Release ${GREEN}${TAG_NAME}${CLEAR}..."
  gh release create "$TAG_NAME" "quickplate-release.apk" \
    --title "QuickPlate Release $TAG_NAME" \
    --notes "$RELEASE_NOTES"
fi

echo -e "\n${GREEN}=== GITHUB RELEASE PUBLISHED SUCCESSFULLY ===${CLEAR}"
echo -e "Tag: ${BLUE}${TAG_NAME}${CLEAR}"
echo -e "Artifact: ${GREEN}quickplate-release.apk${CLEAR}"
echo -e "Release Notes:\n${YELLOW}${RELEASE_NOTES}${CLEAR}"
