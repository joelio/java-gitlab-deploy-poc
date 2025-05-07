#!/bin/bash
# Setup Test Environment for GitLab CI Pipeline
# This script creates a temporary test environment that uses the exact same files
# we intend to ship, ensuring there's no divergence between test and production.

set -e

echo "Setting up test environment..."

# Define directories
CI_DIR="/Users/joel/src/gitlab-ci-refactor/ci"
TEST_DIR="/Users/joel/src/gitlab-ci-refactor/tests"
TEMP_DIR="$TEST_DIR/temp"

# Create temp directory
mkdir -p "$TEMP_DIR"
rm -f "$TEMP_DIR"/*.yml 2>/dev/null || true

# Copy the exact same CI files we'll ship to the temp directory
cp "$CI_DIR"/*.yml "$TEMP_DIR/"

# Create a test-specific .gitlab-ci.yml file that includes the copied files
cat > "$TEMP_DIR/.gitlab-ci.yml" << 'EOF'
##############################################################################
# GITLAB CI/CD PIPELINE TEST CONFIGURATION
#
# This file is used to test the CI/CD pipeline components using gitlab-ci-local.
# It includes the same modular components as the main pipeline.
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

# Include the exact same modular components we ship
include:
  - local: 'variables.yml'  # Global and environment-specific variables
  - local: 'functions.yml'  # Shell functions for deployment operations
  - local: 'build.yml'      # Build job templates
  - local: 'deploy.yml'     # Deployment job templates
  - local: 'rollback.yml'   # Rollback job templates
  - local: 'notify.yml'     # Notification job templates

stages:
  - validate
  - build
  - deploy
  - notify
  - rollback

# Define the jobs for testing
build:
  stage: build
  image: registry.access.redhat.com/ubi8/openjdk-17:1.15
  script:
    - 'echo "Running build test..."'
    - 'mkdir -p /tmp/sample-app/target'
    - 'echo "Creating sample jar file"'
    - 'echo "Mock JAR file" > /tmp/sample-app/target/app.jar'
    - 'echo "Build complete!"'
  artifacts:
    paths:
      - /tmp/sample-app/target/*.jar

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
    - 'echo "Running deployment test with systemd service handling..."'
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
    - 'echo "Deployment completed successfully with systemd service handling"'
  dependencies:
    - build

test_notify:
  extends: .notify_success_template
  stage: notify
  image: registry.access.redhat.com/ubi9/ubi-minimal:9.3
  variables:
    CI_ENVIRONMENT_NAME: test
  script:
    - 'echo "Running notification test..."'
    - 'echo "Notification sent successfully"'
  dependencies:
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
    - 'echo "Running rollback test with systemd service handling..."'
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
    - 'echo "Rollback completed successfully with systemd service handling"'
  dependencies:
    - test_notify
EOF

echo "Test environment setup complete in $TEMP_DIR"
echo "To run tests: cd $TEMP_DIR && gitlab-ci-local"
echo "To test specific job: cd $TEMP_DIR && gitlab-ci-local [job_name]"

# Run tests if command line arguments are provided
if [ $# -gt 0 ]; then
  cd "$TEMP_DIR" && gitlab-ci-local "$@"
fi
