#!/bin/bash --

# Running GenericReader example.

#!/bin/bash --
# Adapted from https://github.com/google/built_value.dart/blob/master/tool/presubmit
# BSD-3 Clause License file: https://github.com/google/built_value.dart/blob/master/LICENSE

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
pub get

# Upgrade packages.
pub upgrade

echo
echo -e "${PURPLE}=== Checking Source Code Formatting${RESET} $PWD..."
echo
# Overwrite files with formatted content: -w
# Dry run: -n
dartfmt -w $(find bin lib -name \*.dart 2>/dev/null)

# Analyze dart files
echo
echo -e "${BLUE}=== Analyzing $PWD...${RESET}"
echo

dartanalyzer \
    --fatal-warnings \
    --fatal-infos \
    --packages="$PWD/.packages" \
    $(find bin lib -name \*.dart 2>/dev/null)


