#!/bin/bash
# Script to validate GitLab CI pipeline configuration using GitLab's built-in CI linter API
# This ensures we test the exact files we ship with no modifications

set -e

# Terminal colors for better readability
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}=================================================${RESET}"
echo -e "${BOLD}${BLUE}  GitLab CI Java Pipeline Validation Tool        ${RESET}"
echo -e "${BOLD}${BLUE}=================================================${RESET}"
echo ""

# Check if required tools are installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed.${RESET}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. Output will not be formatted.${RESET}"
    JQ_INSTALLED=false
else
    JQ_INSTALLED=true
fi

# Prompt for GitLab access token if not provided
if [ -z "$GITLAB_TOKEN" ]; then
    echo -e "${YELLOW}GitLab personal access token not found in environment.${RESET}"
    read -p "Please enter your GitLab personal access token: " GITLAB_TOKEN
    
    if [ -z "$GITLAB_TOKEN" ]; then
        echo -e "${RED}Error: GitLab token is required for API access.${RESET}"
        exit 1
    fi
fi

# Default to gitlab.com if no instance provided
GITLAB_INSTANCE=${GITLAB_INSTANCE:-"gitlab.com"}
GITLAB_API="https://${GITLAB_INSTANCE}/api/v4"

echo -e "${YELLOW}Validating Java-specific GitLab CI pipeline configuration...${RESET}"

# Read and escape the CI configuration
CI_CONFIG=$(cat .gitlab-ci.yml | sed 's/"/\\"/g' | tr '\n' ' ')

# Prepare the JSON request payload
REQUEST_DATA="{\"content\": \"$CI_CONFIG\"}"

# Make the API request to validate the configuration
echo -e "Sending request to GitLab CI Lint API..."
RESPONSE=$(curl --silent --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "$REQUEST_DATA" \
  "$GITLAB_API/ci/lint")

# Extract and display results
if $JQ_INSTALLED; then
    # Parse and display results using jq for better formatting
    VALID=$(echo $RESPONSE | jq -r '.valid')
    ERRORS=$(echo $RESPONSE | jq -r '.errors[]' 2>/dev/null || echo "")
    WARNINGS=$(echo $RESPONSE | jq -r '.warnings[]' 2>/dev/null || echo "")
else
    # Simple parsing for systems without jq
    VALID=$(echo $RESPONSE | grep -o '"valid":[^,}]*' | sed 's/"valid"://')
    ERRORS=$(echo $RESPONSE | grep -o '"errors":\[[^]]*\]' | sed 's/"errors":\[//' | sed 's/\]//')
    WARNINGS=$(echo $RESPONSE | grep -o '"warnings":\[[^]]*\]' | sed 's/"warnings":\[//' | sed 's/\]//')
fi

# Display validation results
echo ""
echo -e "${BOLD}${BLUE}Results:${RESET}"
echo "------------------------------------"

if [ "$VALID" = "true" ]; then
    echo -e "${GREEN}✅ CI configuration is valid!${RESET}"
else
    echo -e "${RED}❌ CI configuration has errors:${RESET}"
    if $JQ_INSTALLED; then
        echo $RESPONSE | jq '.errors'
    else
        echo "$ERRORS"
    fi
fi

# Display warnings if any
if [ -n "$WARNINGS" ] && [ "$WARNINGS" != "null" ]; then
    echo -e "${YELLOW}⚠️ Warnings:${RESET}"
    if $JQ_INSTALLED; then
        echo $RESPONSE | jq '.warnings'
    else
        echo "$WARNINGS"
    fi
fi

echo ""
echo -e "${BOLD}${BLUE}Additional Information:${RESET}"
echo "------------------------------------"

# Check for Java-specific elements
echo -n "Confirming Java-specific configuration: "
if grep -q "java" .gitlab-ci.yml ci/*.yml; then
    echo -e "${GREEN}✅ Found Java references in pipeline${RESET}"
else
    echo -e "${YELLOW}⚠️ No Java references found in main config file${RESET}"
fi

echo ""
echo -e "${BOLD}${BLUE}Summary:${RESET}"
echo "------------------------------------"
if [ "$VALID" = "true" ]; then
    echo -e "${GREEN}✅ Java deployment pipeline configuration is valid and ready for use!${RESET}"
else
    echo -e "${RED}❌ Pipeline configuration needs attention before deployment.${RESET}"
fi
