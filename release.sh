#!/bin/bash

# Exit immediately if any command fails
set -e

# Setup colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0;3m' # No Color
CLEAR='\033[0m'

echo -e "${BLUE}=== QuickPlate Release Manager ===${CLEAR}"

# 1. Check if git working directory is clean (excluding key.properties and untracked config)
if [ -n "$(git status --porcelain | grep -v 'key.properties' | grep -v 'upload-keystore.jks')" ]; then
  echo -e "${YELLOW}Warning: You have uncommitted changes in your git repository.${CLEAR}"
  read -p "Do you want to continue anyway? (y/N) " confirm_git
  if [[ ! "$confirm_git" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Release aborted.${CLEAR}"
    exit 1
  fi
fi

# 2. Parse current version from pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}Error: pubspec.yaml not found in the current directory.${CLEAR}"
  exit 1
fi

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version:[[:space:]]*//g')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

echo -e "Current App Version: ${GREEN}${VERSION_NAME}${CLEAR} (Build Code: ${GREEN}${VERSION_CODE}${CLEAR})"

# Split version name components
MAJOR=$(echo "$VERSION_NAME" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_NAME" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_NAME" | cut -d'.' -f3)

# 3. Choose version increment type
echo -e "\nChoose how to increment version:"
echo "1) Keep Version Name, Increment Build Code only (e.g., ${VERSION_NAME}+$((VERSION_CODE + 1)))"
echo "2) Bump Patch Version (e.g., ${MAJOR}.${MINOR}.$((PATCH + 1))+$((VERSION_CODE + 1)))"
echo "3) Bump Minor Version (e.g., ${MAJOR}.$((MINOR + 1)).0+$((VERSION_CODE + 1)))"
echo "4) Bump Major Version (e.g., $((MAJOR + 1)).0.0+$((VERSION_CODE + 1)))"
echo "5) Custom Version"
read -p "Enter choice [1-5]: " choice

NEW_VERSION_CODE=$((VERSION_CODE + 1))

case $choice in
  1)
    NEW_VERSION_NAME=$VERSION_NAME
    ;;
  2)
    NEW_VERSION_NAME="${MAJOR}.${MINOR}.$((PATCH + 1))"
    ;;
  3)
    NEW_VERSION_NAME="${MAJOR}.$((MINOR + 1)).0"
    ;;
  4)
    NEW_VERSION_NAME="$((MAJOR + 1)).0.0"
    ;;
  5)
    read -p "Enter custom version name (e.g. 1.0.0): " NEW_VERSION_NAME
    read -p "Enter custom build code (e.g. 2): " NEW_VERSION_CODE
    ;;
  *)
    echo -e "${RED}Invalid choice. Aborting.${CLEAR}"
    exit 1
    ;;
esac

NEW_VERSION="${NEW_VERSION_NAME}+${NEW_VERSION_CODE}"
echo -e "\nNew Version: ${GREEN}${NEW_VERSION}${CLEAR}"

# Confirm before proceeding
read -p "Proceed with releasing version $NEW_VERSION? (y/N) " confirm_release
if [[ ! "$confirm_release" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Release aborted.${CLEAR}"
  exit 1
fi

# 4. Update pubspec.yaml
echo -e "\nUpdating pubspec.yaml..."
sed -i "s/^version:.*/version: $NEW_VERSION/g" pubspec.yaml

# 5. Build and Publish Shorebird Release (.aab and .apk)
echo -e "\n${BLUE}Building and Publishing Shorebird Release (Android AppBundle and APK)...${CLEAR}"
shorebird release android --artifact apk --no-confirm

# 7. Commit changes and push Git Tag
echo -e "\n${BLUE}Staging and committing version bump...${CLEAR}"
git add pubspec.yaml
git commit -m "chore: bump version to $NEW_VERSION"

echo -e "Pushing commits to remote..."
git push origin main || echo -e "${YELLOW}Warning: Could not push to main. Please push manually.${CLEAR}"

echo -e "Creating Git tag v$NEW_VERSION..."
git tag "v$NEW_VERSION"
git push origin "v$NEW_VERSION" || echo -e "${YELLOW}Warning: Could not push tag. Please push manually.${CLEAR}"

echo -e "\n${GREEN}=== RELEASE COMPLETED SUCCESSFULLY ===${CLEAR}"
echo -e "1. ${BLUE}Shorebird Base Release${CLEAR} version $NEW_VERSION published."
echo -e "2. ${BLUE}Google Play Store AAB${CLEAR} built at: ${YELLOW}build/app/outputs/bundle/release/app-release.aab${CLEAR}"
echo -e "3. ${BLUE}Shorebird-enabled APK${CLEAR} built at: ${YELLOW}build/app/outputs/apk/release/app-release.apk${CLEAR}"
echo -e "4. ${BLUE}Git Tag v$NEW_VERSION${CLEAR} pushed. (This will trigger the GitHub release CI workflow)."
