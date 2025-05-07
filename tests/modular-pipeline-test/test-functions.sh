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

# SSH command wrapper
ssh_cmd() {
  if is_test_mode; then
    log "TEST" "Would execute SSH command: $@"
    return 0
  fi
  log "INFO" "Executing SSH command on ${DEPLOY_HOST}"
  echo "SSH command executed: $@"
  return 0
}

# Create directories
create_directories() {
  log "INFO" "Creating required directories"
  if is_test_mode; then
    mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "$(dirname $CURRENT_LINK)" "$CONFIG_DIR" "$TMP_DIR"
    log "TEST" "Created test directories"
    return 0
  fi
  return 0
}

# Create deployment directory
create_deployment_dir() {
  local deploy_dir="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
  log "INFO" "Creating deployment directory: $deploy_dir"
  if is_test_mode; then
    mkdir -p "$deploy_dir"
    log "TEST" "Created test deployment directory: $deploy_dir"
  fi
  echo "$deploy_dir"
  return 0
}

# Upload application
upload_application() {
  local deploy_dir=$1
  log "INFO" "Uploading application to $deploy_dir"
  if is_test_mode; then
    cp "$ARTIFACT_PATH" "$deploy_dir/"
    log "TEST" "Uploaded application to $deploy_dir"
    return 0
  fi
  return 0
}

# Setup systemd service
setup_systemd_service() {
  log "INFO" "Setting up systemd service file"
  if is_test_mode; then
    cat > "$CONFIG_DIR/test-app.service" << 'EOSVC'
[Unit]
Description=Test Application Service
After=network.target

[Service]
Type=simple
User=%i
WorkingDirectory=%h/app/current
ExecStart=/bin/sh -c 'java -jar %h/app/current/test-app-1.0.0.jar'
Restart=on-failure

[Install]
WantedBy=default.target
EOSVC
    log "TEST" "Created systemd service file"
    return 0
  fi
  return 0
}

# Stop service
stop_service() {
  log "INFO" "Stopping current service"
  if is_test_mode; then
    log "TEST" "Would execute: systemctl --user stop test-app.service"
    return 0
  fi
  return 0
}

# Update symlink
update_symlink() {
  local target_dir=$1
  log "INFO" "Updating symlink to point to $target_dir"
  if is_test_mode; then
    ln -sfn "$target_dir" "$CURRENT_LINK"
    log "TEST" "Updated symlink to $target_dir"
    return 0
  fi
  return 0
}

# Start service
start_service() {
  log "INFO" "Starting service"
  if is_test_mode; then
    log "TEST" "Would execute: systemctl --user start test-app.service"
    return 0
  fi
  return 0
}

# Health check
perform_health_check() {
  log "INFO" "Performing health check"
  if is_test_mode; then
    log "TEST" "Would execute: curl http://localhost:8080/health"
    return 0
  fi
  return 0
}

# Send notification
send_notification() {
  local status=$1
  local message=$2
  log "INFO" "Sending $status notification"
  if is_test_mode; then
    if [ "$NOTIFICATION_METHOD" == "notification_service" ] && [ -x "$NOTIFICATION_SERVICE_URL" ]; then
      "$NOTIFICATION_SERVICE_URL" "$status" "$message"
    else
      log "TEST" "Would send notification: $message"
    fi
    return 0
  fi
  return 0
}
