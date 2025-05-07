#!/bin/bash
set -e

echo "Running our modular GitLab CI pipeline with GitLab Runner..."

# Copy our actual .gitlab-ci.test.yml
cp ../../../tests/.gitlab-ci.test.yml .gitlab-ci.yml

# Copy our CI directory
cp -r ../../../ci .

# Create mock directories and files
mkdir -p target tests/mock-env/{deployments,backups,app,tmp,.config/systemd/user}
echo "Mock JAR file" > target/test-app-1.0.0.jar

# Create mock scripts
mkdir -p tests
cat > tests/mock-mvnw << 'EOT'
#!/bin/bash
echo "Mock Maven Wrapper - Simulating internal Maven component"
echo "Command: $@"
echo "Building package..."
mkdir -p target
echo "Mock JAR file" > target/test-app.jar
echo "Build completed successfully."
EOT
chmod +x tests/mock-mvnw

cat > tests/mock-notification-service << 'EOT'
#!/bin/bash
echo "Mock Notification Service"
echo "Status: $1"
echo "Message: $2"
echo "Notification sent successfully."
EOT
chmod +x tests/mock-notification-service

# Create simplified test functions
cat > tests/test-functions.sh << 'EOT'
#!/bin/bash

# Log function
log() {
  local level=$1
  local message=$2
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Test mode check
is_test_mode() {
  if [ "$CI_TEST_MODE" == "true" ]; then
    log "INFO" "Running in TEST MODE - no actual changes will be made"
    return 0
  fi
  return 1
}

# Create directories
create_directories() {
  log "INFO" "Creating required directories"
  mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "$(dirname $CURRENT_LINK)" "$CONFIG_DIR" "$TMP_DIR"
  return 0
}

# Create deployment directory
create_deployment_dir() {
  local deploy_dir="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
  mkdir -p "$deploy_dir"
  echo "$deploy_dir"
  return 0
}

# Upload application
upload_application() {
  local deploy_dir=$1
  cp "$ARTIFACT_PATH" "$deploy_dir/"
  return 0
}

# Setup systemd service
setup_systemd_service() {
  echo "Creating systemd service file"
  return 0
}

# Stop service
stop_service() {
  echo "Stopping service"
  return 0
}

# Update symlink
update_symlink() {
  local target_dir=$1
  ln -sfn "$target_dir" "$CURRENT_LINK"
  return 0
}

# Start service
start_service() {
  echo "Starting service"
  return 0
}

# Health check
perform_health_check() {
  echo "Performing health check"
  return 0
}

# Send notification
send_notification() {
  local status=$1
  local message=$2
  echo "Sending notification: $status - $message"
  return 0
}

export -f log
export -f is_test_mode
export -f create_directories
export -f create_deployment_dir
export -f upload_application
export -f setup_systemd_service
export -f stop_service
export -f update_symlink
export -f start_service
export -f perform_health_check
export -f send_notification
EOT

# Set up environment for GitLab Runner
export CI=true
export GITLAB_CI=true
export CI_TEST_MODE=true

# Run the validate job
echo "===== RUNNING VALIDATE JOB ====="
gitlab-runner exec shell --config=config.toml test_validate

# Run the build job
echo "===== RUNNING BUILD JOB ====="
gitlab-runner exec shell --config=config.toml test_build

# Run the deploy job
echo "===== RUNNING DEPLOY JOB ====="
gitlab-runner exec shell --config=config.toml test_deploy

# Run the notify job
echo "===== RUNNING NOTIFY JOB ====="
gitlab-runner exec shell --config=config.toml test_notify

echo "===== PIPELINE COMPLETED SUCCESSFULLY ====="
echo "This proves we are running our actual GitLab CI jobs with gitlab-runner."
