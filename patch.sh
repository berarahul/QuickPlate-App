#!/bin/bash

# Exit immediately if any command fails
set -e

# Setup colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m'

echo -e "${BLUE}=== Shorebird Patch Manager ===${CLEAR}"

# 1. Parse current version from pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}Error: pubspec.yaml not found in the current directory.${CLEAR}"
  exit 1
fi

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version:[[:space:]]*//g')
echo -e "Current App Version: ${GREEN}${CURRENT_VERSION}${CLEAR}"
echo -e "This script will push an OTA (Over-The-Air) patch targeting version: ${GREEN}${CURRENT_VERSION}${CLEAR}"

# Confirm before proceeding
read -p "Proceed with pushing Shorebird patch? (y/N) " confirm_patch
if [[ ! "$confirm_patch" =~ ^[Yy]$ ]]; then
  echo -e "${RED}Patch aborted.${CLEAR}"
  exit 1
fi

# 2. Run Shorebird patch command
echo -e "\n${BLUE}Building and publishing Shorebird patch...${CLEAR}"
shorebird patch android --no-confirm

echo -e "\n${GREEN}=== PATCH SHIPPED SUCCESSFULLY ===${CLEAR}"
echo -e "Shorebird OTA patch for version ${GREEN}${CURRENT_VERSION}${CLEAR} has been successfully published."
