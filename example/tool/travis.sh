#!/bin/bash --

# Running GenericReader example.

# Defining colours
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'
PURPLE='\033[1;35m'

# Exit immediately if a command exits with a non-zero status.
set -e

# Folder name
FOLDER=$(basename $PWD)

echo
echo -e "${CYAN}=== Preparing Example $PWD...${RESET}"
echo

# Running example
echo
echo -e "${GREEN}=== Running Examples $PWD...${RESET}"
echo

cd ..
dart example/bin/player_example.dart
dart example/bin/wrapper_example.dart

echo
