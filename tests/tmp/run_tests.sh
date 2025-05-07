#!/bin/bash
# Run the CI tests using gitlab-ci-local

set -e

TEST_DIR="/Users/joel/src/gitlab-ci-refactor/tests"
TEMP_DIR="$TEST_DIR/tmp"

# Ensure temp directory exists
mkdir -p "$TEMP_DIR"

# Run gitlab-ci-local with our test file
echo "Running GitLab CI tests with original include files..."
cd "$TEMP_DIR"
gitlab-ci-local --file .gitlab-ci.test.yml "$@"

echo "Test completed. Original files were not modified."
