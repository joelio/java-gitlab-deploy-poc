#!/bin/bash
# Simplified test functions for GitLab CI local testing

# Log function with timestamp and log level
function log() {
  local level=$1
  local message=$2
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Test mode check function
function is_test_mode() {
  if [ "$CI_TEST_MODE" == "true" ]; then
    log "INFO" "Running in TEST MODE - no actual changes will be made"
    return 0
  fi
  return 1
}

# Create required directories with validation
function create_directories() {
  log "INFO" "Creating required directories"
  
  mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "$(dirname $CURRENT_LINK)" "$CONFIG_DIR" "$TMP_DIR"
  log "TEST" "Created test directories"
  return 0
}

# Create a new deployment directory with timestamp and job ID
function create_deployment_dir() {
  local deploy_dir="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
  
  log "INFO" "Creating deployment directory: $deploy_dir"
  mkdir -p "$deploy_dir"
  log "TEST" "Created test deployment directory: $deploy_dir"
  
  # Return only the path, no log messages
  echo "$deploy_dir"
  return 0
}

# Upload application to deployment directory
function upload_application() {
  local deploy_dir=$1
  
  log "INFO" "Uploading application to $deploy_dir"
  cp "$ARTIFACT_PATH" "$deploy_dir/"
  log "TEST" "Uploaded application to $deploy_dir"
  return 0
}

# Setup systemd service file
function setup_systemd_service() {
  log "INFO" "Setting up systemd service file"
  
  # Create a mock systemd service file
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_DIR/${APP_NAME}.service" << EOF
[Unit]
Description=${APP_NAME} Service
After=network.target

[Service]
Type=simple
ExecStart=java -jar ${CURRENT_LINK}/${ARTIFACT_NAME}
Restart=on-failure

[Install]
WantedBy=default.target
EOF
  
  log "TEST" "Created systemd service file: $CONFIG_DIR/${APP_NAME}.service"
  return 0
}

# Stop the current service
function stop_service() {
  log "INFO" "Stopping current service"
  log "TEST" "Would execute: systemctl --user stop ${APP_NAME}.service"
  return 0
}

# Update symlink to point to the new deployment
function update_symlink() {
  local target_dir=$1
  
  log "INFO" "Updating symlink to point to $target_dir"
  mkdir -p "$(dirname "$CURRENT_LINK")"
  ln -sfn "$target_dir" "$CURRENT_LINK"
  log "TEST" "Updated symlink to $target_dir"
  return 0
}

# Start the service
function start_service() {
  log "INFO" "Starting service"
  log "TEST" "Would execute: systemctl --user start ${APP_NAME}.service"
  return 0
}

# Perform health check
function perform_health_check() {
  log "INFO" "Performing health check"
  log "TEST" "Would execute: curl http://localhost:8080/health"
  return 0
}

# Send notification
function send_notification() {
  local status=$1
  local message=$2
  
  log "INFO" "Sending $status notification"
  
  if [ -x "$NOTIFICATION_SERVICE_URL" ]; then
    "$NOTIFICATION_SERVICE_URL" "$status" "$message"
  else
    log "TEST" "Would send notification: $message"
  fi
  
  return 0
}

# Get last successful deploy ID
function get_last_successful_deploy() {
  log "INFO" "Getting last successful deployment"
  
  # In test mode, just return the current deployment directory
  local deploy_dirs=("$DEPLOY_DIR"/*-*)
  if [ ${#deploy_dirs[@]} -gt 1 ]; then
    echo "${deploy_dirs[-2]}"
  else
    echo "${deploy_dirs[0]}"
  fi
  
  return 0
}

# Export functions
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
export -f get_last_successful_deploy
