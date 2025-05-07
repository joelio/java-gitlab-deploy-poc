#!/bin/bash
# Basic test functions for GitLab CI local testing
# These functions are simplified to focus on demonstrating the pipeline flow

# Create required directories
function create_directories() {
  echo "Creating required directories..."
  mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "$(dirname $CURRENT_LINK)" "$CONFIG_DIR" "$TMP_DIR"
  return 0
}

# Create a new deployment directory
function create_deployment_dir() {
  local deploy_dir="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
  echo "Creating deployment directory: $deploy_dir"
  mkdir -p "$deploy_dir"
  echo "$deploy_dir"
  return 0
}

# Upload application to deployment directory
function upload_application() {
  local deploy_dir=$1
  echo "Uploading application to $deploy_dir"
  cp "$ARTIFACT_PATH" "$deploy_dir/"
  return 0
}

# Setup systemd service file
function setup_systemd_service() {
  echo "Setting up systemd service file"
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
  return 0
}

# Stop the current service
function stop_service() {
  echo "Stopping current service"
  echo "Would execute: systemctl --user stop ${APP_NAME}.service"
  return 0
}

# Update symlink to point to the new deployment
function update_symlink() {
  local target_dir=$1
  echo "Updating symlink to point to $target_dir"
  mkdir -p "$(dirname "$CURRENT_LINK")"
  ln -sfn "$target_dir" "$CURRENT_LINK"
  return 0
}

# Start the service
function start_service() {
  echo "Starting service"
  echo "Would execute: systemctl --user start ${APP_NAME}.service"
  return 0
}

# Perform health check
function perform_health_check() {
  echo "Performing health check"
  echo "Would execute: curl http://localhost:8080/health"
  return 0
}

# Send notification
function send_notification() {
  local status=$1
  local message=$2
  echo "Sending $status notification: $message"
  if [ -x "$NOTIFICATION_SERVICE_URL" ]; then
    "$NOTIFICATION_SERVICE_URL" "$status" "$message"
  fi
  return 0
}

# Get last successful deploy ID
function get_last_successful_deploy() {
  echo "Getting last successful deployment"
  local deploy_dirs=("$DEPLOY_DIR"/*-*)
  if [ ${#deploy_dirs[@]} -gt 1 ]; then
    echo "${deploy_dirs[-2]}"
  else
    echo "${deploy_dirs[0]}"
  fi
  return 0
}

# Export functions
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
