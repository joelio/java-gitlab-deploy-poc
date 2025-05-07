#!/bin/bash
# Test functions extracted from functions.yml for local testing

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

# SSH command wrapper function with error handling
function ssh_cmd() {
  if is_test_mode; then
    log "TEST" "Would execute SSH command: $@"
    return 0
  fi
  
  log "DEBUG" "Executing SSH command on ${APP_USER}@${DEPLOY_HOST}"
  echo "SSH command executed: $@"
  return 0
}

# SCP command wrapper function with error handling
function scp_cmd() {
  if is_test_mode; then
    log "TEST" "Would execute SCP command: $1 to ${APP_USER}@${DEPLOY_HOST}:$2"
    return 0
  fi
  
  log "DEBUG" "Copying $1 to ${APP_USER}@${DEPLOY_HOST}:$2"
  echo "SCP command executed: $1 to $2"
  return 0
}

# Create required directories with validation
function create_directories() {
  log "INFO" "Creating required directories on ${DEPLOY_HOST}"
  
  if is_test_mode; then
    mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "${BASE_PATH}/app" "$TMP_DIR" "$CONFIG_DIR"
    log "TEST" "Created test directories"
    return 0
  else
    ssh_cmd "mkdir -p $DEPLOY_DIR $BACKUP_DIR ${BASE_PATH}/app $TMP_DIR $CONFIG_DIR"
  fi
  
  log "INFO" "Successfully created directories"
  return 0
}

# Backup current deployment with timestamp
function backup_current_deployment() {
  log "INFO" "Checking for existing deployment to backup"
  
  if is_test_mode; then
    log "TEST" "Would backup current deployment"
    return 0
  fi
  
  log "INFO" "Backup completed successfully"
  return 0
}

# Create a new deployment directory with timestamp and job ID
function create_deployment_dir() {
  local timestamp=$(date +%Y%m%d%H%M%S)
  local deploy_dir="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
  
  log "INFO" "Creating deployment directory: $deploy_dir"
  
  if is_test_mode; then
    mkdir -p "$deploy_dir"
    log "TEST" "Created test deployment directory: $deploy_dir"
  else
    ssh_cmd "mkdir -p $deploy_dir"
  fi
  
  # Return only the path, no log messages
  echo "$deploy_dir"
  return 0
}

# Upload application to deployment directory
function upload_application() {
  local deploy_dir=$1
  
  if [ -z "$deploy_dir" ]; then
    log "ERROR" "No deployment directory specified"
    return 1
  fi
  
  log "INFO" "Uploading application to $deploy_dir"
  
  if is_test_mode; then
    log "TEST" "Would upload application to $deploy_dir"
    return 0
  fi
  
  log "INFO" "Application uploaded successfully"
  return 0
}

# Setup systemd service file
function setup_systemd_service() {
  log "INFO" "Setting up systemd service file"
  
  if is_test_mode; then
    log "TEST" "Would setup systemd service"
    return 0
  fi
  
  log "INFO" "Systemd service setup successfully"
  return 0
}

# Stop the current service
function stop_service() {
  log "INFO" "Stopping current service"
  
  if is_test_mode; then
    log "TEST" "Would stop current service"
    return 0
  fi
  
  log "INFO" "Service stopped successfully"
  return 0
}

# Update symlink to point to the new deployment
function update_symlink() {
  local target_dir=$1
  
  if [ -z "$target_dir" ]; then
    log "ERROR" "No target directory specified for symlink"
    return 1
  fi
  
  log "INFO" "Updating symlink to point to $target_dir"
  
  if is_test_mode; then
    mkdir -p "$(dirname "$CURRENT_LINK")"
    ln -sfn "$target_dir" "$CURRENT_LINK"
    log "TEST" "Updated test symlink to $target_dir"
    return 0
  fi
  
  log "INFO" "Symlink updated successfully"
  return 0
}

# Enable linger for user service persistence
function enable_linger() {
  log "INFO" "Enabling linger for ${APP_USER}"
  
  if is_test_mode; then
    log "TEST" "Would enable linger for ${APP_USER}"
    return 0
  fi
  
  log "INFO" "Linger enabled successfully"
  return 0
}

# Start the service
function start_service() {
  log "INFO" "Starting service"
  
  if is_test_mode; then
    log "TEST" "Would start service"
    return 0
  fi
  
  log "INFO" "Service started successfully"
  return 0
}

# Perform health check
function perform_health_check() {
  log "INFO" "Performing health check"
  
  if is_test_mode; then
    log "TEST" "Would perform health check"
    return 0
  fi
  
  log "INFO" "Health check passed"
  return 0
}

# Send notification
function send_notification() {
  local status=$1
  local message=$2
  
  log "INFO" "Sending $status notification"
  
  if [ -z "$message" ]; then
    message="Deployment ${status} for ${APP_NAME} in ${CI_ENVIRONMENT_NAME} environment"
  fi
  
  if is_test_mode; then
    log "TEST" "Would send notification: $message"
    return 0
  fi
  
  if [ "$NOTIFICATION_METHOD" == "email" ]; then
    log "INFO" "Sending email notification to $NOTIFICATION_EMAIL"
    echo "Email notification sent: $message"
  elif [ "$NOTIFICATION_METHOD" == "notification_service" ]; then
    if [ -z "$NOTIFICATION_SERVICE_URL" ]; then
      log "WARN" "NOTIFICATION_SERVICE_URL not set. Skipping notification."
      return 0
    fi
    
    log "INFO" "Sending notification to service"
    if [ -f "$NOTIFICATION_SERVICE_URL" ] && [ -x "$NOTIFICATION_SERVICE_URL" ]; then
      "$NOTIFICATION_SERVICE_URL" "$message"
    else
      echo "Notification service called with message: $message"
    fi
  else
    log "WARN" "Notification method $NOTIFICATION_METHOD not configured. Defaulting to console output."
    echo "NOTIFICATION: $message"
  fi
  
  return 0
}

# Get last successful deploy ID
function get_last_successful_deploy() {
  log "INFO" "Getting last successful deploy ID"
  
  if is_test_mode; then
    log "TEST" "Would get last successful deploy ID"
    return 0
  fi
  
  return 0
}

# Get latest backup
function get_latest_backup() {
  log "INFO" "Finding latest backup"
  
  if is_test_mode; then
    log "TEST" "Would find latest backup"
    echo "test-backup-$(date +%Y%m%d%H%M%S)"
    return 0
  fi
  
  return 0
}

# Clean up old backups
function cleanup_old_backups() {
  log "INFO" "Cleaning up old backups (keeping $MAX_BACKUPS)"
  
  if is_test_mode; then
    log "TEST" "Would clean up old backups"
    return 0
  fi
  
  log "INFO" "Backup cleanup completed"
  return 0
}

# Export functions
export -f log
export -f is_test_mode
export -f ssh_cmd
export -f scp_cmd
export -f create_directories
export -f backup_current_deployment
export -f create_deployment_dir
export -f upload_application
export -f setup_systemd_service
export -f stop_service
export -f update_symlink
export -f enable_linger
export -f start_service
export -f perform_health_check
export -f send_notification
export -f get_last_successful_deploy
export -f get_latest_backup
export -f cleanup_old_backups
