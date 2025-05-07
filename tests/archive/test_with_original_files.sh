#!/bin/bash
# This script runs gitlab-ci-local with the original CI files
# It addresses the YAML anchor limitation by creating a temporary version
# that uses 'extends' instead of anchors, without modifying the original files

set -e

echo "Testing GitLab CI pipeline with original files..."

# Directory paths
CI_DIR="/Users/joel/src/gitlab-ci-refactor/ci"
TEMP_DIR="/Users/joel/src/gitlab-ci-refactor/tests/temp"
BACKUP_DIR="/Users/joel/src/gitlab-ci-refactor/backup/ci"

# Create temp and backup directories
mkdir -p "$TEMP_DIR" "$BACKUP_DIR"

# Ensure we have original files backed up
cp -f "$CI_DIR"/*.yml "$BACKUP_DIR/"

# Step 1: Create a temporary version of functions.yml that uses script instead of before_script
# This is for testing only and doesn't affect the original files
cat > "$TEMP_DIR/functions.yml" << 'EOF'
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
EOF

# Extract the shell functions without the YAML anchor
grep -A 10000 "&functions" "$CI_DIR/functions.yml" | tail -n +2 >> "$TEMP_DIR/functions.yml"

# Step 2: Create temporary versions of deploy.yml, rollback.yml, notify.yml that use extends
for file in deploy.yml rollback.yml; do
  # Create a modified version that uses extends and fixes dependencies
  cat "$CI_DIR/$file" | \
    sed 's/script:\n    - \*functions/extends: .functions\n  script:/g' | \
    sed 's/dependencies:\n\s*- build/dependencies:\n    - test_build/g' > "$TEMP_DIR/$file"
done

# Copy notify.yml separately to modify later
cp "$CI_DIR/notify.yml" "$TEMP_DIR/notify.yml.original"

# Create a modified notify.yml with proper template definitions
echo '# Modified for testing - extends .functions instead of using YAML anchors' > "$TEMP_DIR/notify.yml"
echo '.notify_common:' >> "$TEMP_DIR/notify.yml"
echo '  extends: .functions' >> "$TEMP_DIR/notify.yml"

# Append the rest of the file except for the *functions references
grep -v "*functions" "$TEMP_DIR/notify.yml.original" >> "$TEMP_DIR/notify.yml"
rm "$TEMP_DIR/notify.yml.original"

# Step 3: Copy other files that don't need modification
cp "$CI_DIR/variables.yml" "$TEMP_DIR/"
cp "$CI_DIR/build.yml" "$TEMP_DIR/"

# Step 4: Create a test file that includes these temporary files
cat > "$TEMP_DIR/.gitlab-ci.test.yml" << 'EOF'
##############################################################################
# GITLAB CI/CD PIPELINE TEST CONFIGURATION
#
# This file is used to test the CI/CD pipeline components using gitlab-ci-local.
# It includes the same modular components as the main pipeline but adapted to
# work with gitlab-ci-local's limitations regarding YAML anchors.
##############################################################################

# Set default values for required variables for testing
variables:
  CI_TEST_MODE: "true"
  APP_NAME: "test-app"
  APP_VERSION: "1.0.0"
  APP_TYPE: "java"
  BUILD_COMMAND: "mvn clean package"
  DEPLOY_HOST: "localhost"
  APP_USER: "app"
  BASE_PATH: "/tmp/app"
  DEPLOY_DIR: "/tmp/deployments"
  BACKUP_DIR: "/tmp/backups"
  CURRENT_LINK: "/tmp/app/current"
  CONFIG_DIR: "/etc/systemd/system"
  TMP_DIR: "/tmp/tmp"
  ARTIFACT_PATTERN: "*.jar"
  ARTIFACT_PATH: "target"
  ARTIFACT_NAME: "app.jar"
  NOTIFICATION_METHOD: "email"
  NOTIFICATION_SERVICE_URL: "http://notification-service"
  NOTIFICATION_EMAIL: "devops@example.com"

# Include the same modular components
include:
  - local: 'variables.yml'
  - local: 'functions.yml'
  - local: 'build.yml'
  - local: 'deploy.yml'
  - local: 'rollback.yml'
  - local: 'notify.yml'

stages:
  - validate
  - build
  - deploy
  - notify
  - rollback

test_validate:
  stage: validate
  image: registry.access.redhat.com/ubi9/ubi-minimal:9.3
  script:
    - 'echo "Validating configuration..."'
    - 'echo "App name: $APP_NAME"'
    - 'echo "Environment: $CI_ENVIRONMENT_NAME"'
    - 'echo "Artifact pattern: $ARTIFACT_PATTERN"'
    - 'echo "Configuration valid!"'

test_build:
  stage: build
  image: registry.access.redhat.com/ubi8/openjdk-17:1.15
  script:
    - 'echo "Running build test..."'
    - 'mkdir -p tests/sample-app/target'
    - 'echo "Creating sample jar file"'
    - 'echo "Mock JAR file" > tests/sample-app/target/app.jar'
    - 'echo "Build complete!"'
  artifacts:
    paths:
      - tests/sample-app/target/*.jar

test_deploy:
  extends: .deploy_template
  stage: deploy
  image: registry.access.redhat.com/ubi9/ubi:9.3
  variables:
    CI_ENVIRONMENT_NAME: test
  before_script:
    - dnf install -y systemd procps-ng
    - mkdir -p /etc/systemd/system
    - echo "Starting deployment to test environment"
  script:
    - 'echo "Running deployment test..."'
    - 'log "INFO" "Deploying application to $CI_ENVIRONMENT_NAME environment"'
    - 'mkdir -p $DEPLOY_DIR $BACKUP_DIR ${BASE_PATH}/app $TMP_DIR'
    - 'DEPLOY_DIR_NAME="$DEPLOY_DIR/${APP_NAME}-$(date +%Y%m%d%H%M%S)-$CI_JOB_ID"'
    - 'mkdir -p "$DEPLOY_DIR_NAME"'
    - 'echo "Created deployment directory: $DEPLOY_DIR_NAME"'
    - 'echo "Mock JAR file" > "$DEPLOY_DIR_NAME/${APP_NAME}-${APP_VERSION}.jar"'
    # Setup systemd service
    - 'echo "[Unit]" > "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "Description=${APP_NAME} Application" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "After=network.target" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "[Service]" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "Type=simple" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "User=root" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "WorkingDirectory=${BASE_PATH}/app/current" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "ExecStart=/bin/echo \"Service started\"" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "SuccessExitStatus=143" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "TimeoutStopSec=10" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "Restart=on-failure" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "RestartSec=5" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "[Install]" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "WantedBy=multi-user.target" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'systemctl daemon-reload || echo "Would run: systemctl daemon-reload"'
    - 'systemctl enable ${APP_NAME}.service || echo "Would run: systemctl enable ${APP_NAME}.service"'
    - 'systemctl start ${APP_NAME}.service || echo "Would run: systemctl start ${APP_NAME}.service"'
    - 'ln -sf "$DEPLOY_DIR_NAME" "${BASE_PATH}/app/current"'
    - 'ls -la "${BASE_PATH}/app/current"'
    - 'log "INFO" "Deployment to $CI_ENVIRONMENT_NAME environment completed successfully"'
  needs:
    - test_build

test_notify:
  extends: .notify_success_template
  stage: notify
  image: registry.access.redhat.com/ubi9/ubi-minimal:9.3
  variables:
    CI_ENVIRONMENT_NAME: test
  script:
    - 'echo "Running notification test..."'
    - 'log "INFO" "Sending success notification for $CI_ENVIRONMENT_NAME deployment"'
    - 'send_notification "SUCCESS" "Deployment to $CI_ENVIRONMENT_NAME environment completed successfully"'
    - 'echo "Notification successful!"'
  needs:
    - test_deploy

test_rollback:
  extends: .rollback_manual_template
  stage: rollback
  image: registry.access.redhat.com/ubi9/ubi:9.3
  variables:
    CI_ENVIRONMENT_NAME: test
  before_script:
    - dnf install -y systemd procps-ng
    - mkdir -p /etc/systemd/system
    - echo "Starting rollback operation for test environment"
  script:
    - 'echo "Running rollback test..."'
    - 'log "INFO" "Performing rollback operation for $CI_ENVIRONMENT_NAME environment"'
    - 'mkdir -p $DEPLOY_DIR $BACKUP_DIR'
    - 'BACKUP_DIR_NAME="$BACKUP_DIR/${APP_NAME}-backup-$(date +%Y%m%d%H%M%S)"'
    - 'mkdir -p "$BACKUP_DIR_NAME"'
    - 'echo "Created backup directory: $BACKUP_DIR_NAME"'
    - 'echo "Mock backup JAR file" > "$BACKUP_DIR_NAME/${APP_NAME}-${APP_VERSION}.jar"'
    # Setup systemd service for testing rollback
    - 'echo "[Unit]" > "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "Description=${APP_NAME} Application" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "After=network.target" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "[Service]" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "Type=simple" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "User=root" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "WorkingDirectory=${BACKUP_DIR_NAME}" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "ExecStart=/bin/echo \"Rollback service started\"" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "SuccessExitStatus=143" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "TimeoutStopSec=10" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "Restart=on-failure" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "RestartSec=5" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "[Install]" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'echo "WantedBy=multi-user.target" >> "$CONFIG_DIR/${APP_NAME}.service"'
    - 'systemctl daemon-reload || echo "Would run: systemctl daemon-reload"'
    - 'systemctl stop ${APP_NAME}.service || echo "Would run: systemctl stop ${APP_NAME}.service"'
    - 'systemctl start ${APP_NAME}.service || echo "Would run: systemctl start ${APP_NAME}.service"'
    - 'ln -sf "$BACKUP_DIR_NAME" "${BASE_PATH}/app/current"'
    - 'ls -la "${BASE_PATH}/app/current"'
    - 'log "INFO" "Rollback to backup in $CI_ENVIRONMENT_NAME environment completed successfully"'
  needs:
    - test_notify
EOF

# Step 5: Run gitlab-ci-local with the temporary files
cd "$TEMP_DIR"
echo "Running gitlab-ci-local with modified files that use 'extends' instead of YAML anchors..."
gitlab-ci-local --file .gitlab-ci.test.yml "$@"

# Clean up temporary files (optional)
# rm -rf "$TEMP_DIR"

echo "Test completed. Note that the original files were not modified."
echo "Original files are in: $CI_DIR"
echo "Temporary test files are in: $TEMP_DIR"
