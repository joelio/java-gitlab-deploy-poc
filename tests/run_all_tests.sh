#!/bin/bash
# Main test driver for GitLab CI/CD pipeline
# Executes all tests in sequence, from basic to comprehensive

set -e

# Terminal colors
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"

echo -e "${BOLD}${BLUE}====================================================${RESET}"
echo -e "${BOLD}${BLUE}   GitLab CI/CD Pipeline Comprehensive Test Suite   ${RESET}"
echo -e "${BOLD}${BLUE}====================================================${RESET}"
echo ""
echo -e "This script will run all tests in sequence, from basic to comprehensive."
echo -e "The tests ensure that ${BOLD}\"the files we want to ship are the files under test,${RESET}"
echo -e "with ${BOLD}no divergence from that end state.\"${RESET}"
echo ""

# Function to run a test and report the result
run_test() {
  local test_script=$1
  local test_name=$2
  local test_description=$3
  
  echo -e "${BOLD}${YELLOW}=== Running: ${test_name} ===${RESET}"
  echo -e "${test_description}"
  echo ""
  
  if [ -x "$test_script" ]; then
    if $test_script; then
      echo -e "${BOLD}${GREEN}✓ $test_name passed${RESET}"
      return 0
    else
      echo -e "${BOLD}${RED}✗ $test_name failed${RESET}"
      return 1
    fi
  else
    echo -e "${BOLD}${RED}✗ Error: $test_script is not executable${RESET}"
    chmod +x "$test_script"
    echo -e "${BOLD}${YELLOW}→ Made $test_script executable, trying again...${RESET}"
    if $test_script; then
      echo -e "${BOLD}${GREEN}✓ $test_name passed${RESET}"
      return 0
    else
      echo -e "${BOLD}${RED}✗ $test_name failed${RESET}"
      return 1
    fi
  fi
}

# Function to clean up unneeded files
cleanup_unneeded_files() {
  echo -e "${BOLD}${YELLOW}=== Cleaning up unneeded files ===${RESET}"
  echo -e "Removing temporary and backup files that aren't needed for the pipeline."
  echo ""
  
  # Find and remove backup files and temporary files
  find "$BASE_DIR/.." -name "*.bak" -type f -delete
  find "$BASE_DIR/.." -name "*~" -type f -delete
  find "$BASE_DIR/.." -name "*.tmp" -type f -delete
  find "$BASE_DIR/.." -name "*.fixed" -type f -delete
  
  echo -e "${BOLD}${GREEN}✓ Cleanup completed${RESET}"
  echo ""
}

# Get the base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

# Clean up unneeded files before running tests
cleanup_unneeded_files

# Run the basic test first
echo -e "${BOLD}STAGE 1: Basic Pipeline Structure Testing${RESET}"
run_test "./test_pipeline.sh" "Basic Pipeline Test" "Validates the pipeline structure and job dependencies."
echo ""

# Run our new comprehensive GitLab CI local test that uses the exact files we'll ship
echo -e "${BOLD}STAGE 2: Comprehensive GitLab CI Local Testing with Actual Components${RESET}"
run_test "./run_gitlab_ci_local_tests.sh" "GitLab CI Local Testing with Actual Components" "Tests all pipeline components using the exact files that will be shipped, including rollback functionality."
echo ""

# Run the systemd rollback test
echo -e "${BOLD}STAGE 3: Systemd Service and Rollback Testing${RESET}"
run_test "./test_systemd_rollback.sh" "Systemd Rollback Test" "Tests systemd service handling and basic rollback functionality."
echo ""

# Run the gitlab-ci-local comprehensive test
echo -e "${BOLD}STAGE 4: GitLab CI Local Comprehensive Testing${RESET}"
run_test "./gitlab_ci_local_comprehensive.sh" "GitLab CI Local Comprehensive Test" "Tests all pipeline actions using gitlab-ci-local: builds, deployments, systemd services, and rollbacks."
echo ""

# Run the comprehensive pipeline test
echo -e "${BOLD}STAGE 5: Comprehensive Pipeline Testing${RESET}"
run_test "./comprehensive_pipeline_test.sh" "Comprehensive Pipeline Test" "Performs complete testing of all pipeline aspects including edge cases and multi-server deployments."
echo ""

# Final cleanup of any temporary files created during testing
cleanup_unneeded_files

echo -e "${BOLD}${GREEN}====================================================${RESET}"
echo -e "${BOLD}${GREEN}   All tests completed successfully!   ${RESET}"
echo -e "${BOLD}${GREEN}====================================================${RESET}"
echo ""
echo -e "This confirms that the GitLab CI/CD pipeline is working correctly."
echo -e "The tests validate that the exact same files we ship to users work in all scenarios."
echo -e "${BOLD}\"The files we want to ship are the files under test, with no divergence from that end state.\"${RESET}"
