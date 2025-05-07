#!/bin/bash
# This script converts YAML anchors to extends in GitLab CI files
# It modifies the files in place to use extends instead of YAML anchors
# This ensures that the files we ship are exactly the files under test

set -e

# Directory paths
CI_DIR="/Users/joel/src/gitlab-ci-refactor/ci"
BACKUP_DIR="/Users/joel/src/gitlab-ci-refactor/backup/ci"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup original files
echo "Backing up original files..."
cp -f "$CI_DIR"/*.yml "$BACKUP_DIR/"

# Step 1: Extract the functions from functions.yml
echo "Extracting functions from functions.yml..."
FUNCTIONS_CONTENT=$(grep -A 1000 "&functions" "$CI_DIR/functions.yml" | tail -n +2)

# Step 2: Update functions.yml to define functions as a hidden job
echo "Updating functions.yml..."
cat > "$CI_DIR/functions.yml" << EOF
##############################################################################
# DEPLOYMENT FUNCTIONS
#
# This file defines all shell functions used throughout the CI/CD pipeline for
# deployment operations. These functions handle SSH connections, file transfers,
# service management, and deployment validation.
#
# KEY FEATURES:
# - Comprehensive error handling and validation for all operations
# - Detailed logging with timestamps and log levels
# - Test mode support to simulate operations without making changes
# - Fallback mechanisms for critical operations
#
# HOW TO USE:
# 1. These functions are referenced in other CI files using the extends keyword
# 2. Each function returns a non-zero exit code on failure for proper error handling
# 3. For testing without making actual changes, set CI_TEST_MODE to "true"
#
# CUSTOMIZATION:
# - Add new functions as needed for your specific deployment requirements
# - Modify existing functions to match your infrastructure setup
##############################################################################

.functions:
  script:
    - |
$FUNCTIONS_CONTENT
EOF

# Step 3: Update files that use *functions to use extends instead
echo "Updating deploy.yml..."
sed -i '' 's/script:\n    - \*functions/extends: .functions\n  script:/g' "$CI_DIR/deploy.yml"

echo "Updating rollback.yml..."
sed -i '' 's/script:\n    - \*functions/extends: .functions\n  script:/g' "$CI_DIR/rollback.yml"

echo "Updating notify.yml..."
sed -i '' 's/script:\n    - \*functions/extends: .functions\n  script:/g' "$CI_DIR/notify.yml"

echo "Conversion complete. Files have been updated to use extends instead of YAML anchors."
echo "Original files are backed up in $BACKUP_DIR"
echo "You can now run gitlab-ci-local with the updated files."
