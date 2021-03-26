#!/bin/bash --

# Defining colours
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
RESET='\033[0m'


# Exit immediately if a command exits with a non-zero status.
set -e

# Resolving dependencies
echo
echo -e "${BLUE}=== Resolving dependencies $PWD...${RESET}"
echo

# Make sure .dart_tool/package_config.json exists.
dart pub get

# Upgrade packages.
pub upgrade

echo
echo -e "${PURPLE}=== Checking Source Code Formatting${RESET} $PWD..."
echo
# Overwrite files with formatted content
dart format lib test example

# Analyze dart files
echo
echo -e "${BLUE}=== Analyzing $PWD...${RESET}"
echo

dart analyze \
    --fatal-warnings \
    --fatal-infos

# Running tests
echo
echo -e "${CYAN}=== Testing $PWD...${RESET}"
echo

# Only run if libary has test dependency
dart test -r expanded --test-randomize-ordering-seed=random


# ==============================
# Running examples and benchmark
# ===============================

# Directories to be processed
directories="example/test_types"

for directory in $directories; do
  cd $directory
  ./tool/actions.sh
  cd ..
  cd ..
done

# ================
# Running examples
# ================

# Running example
echo
echo -e "${GREEN}=== Running Examples $PWD...${RESET}"
echo


dart example/bin/player_example.dart
dart example/bin/wrapper_example.dart

echo
