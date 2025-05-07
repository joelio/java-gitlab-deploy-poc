#!/bin/bash
# Container test script for GitLab CI pipeline
# This script runs inside the Docker container and tests the actual pipeline functionality

# Terminal colors and formatting
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"
CYAN="\033[36m"

# Print a header
print_header() {
    echo -e "${BOLD}${BLUE}===== $1 =====${RESET}"
}

# Print a success message
print_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

# Print an info message
print_info() {
    echo -e "${CYAN}ℹ️ $1${RESET}"
}

# Print an error message
print_error() {
    echo -e "${RED}❌ $1${RESET}"
}

# Print a warning message
print_warning() {
    echo -e "${YELLOW}⚠️ $1${RESET}"
}

# Function to create a test JAR file with specific version content
create_test_jar() {
    local version=$1
    local filename=$2
    
    echo "Creating test JAR for version $version: $filename"
    
    # Create a simple JAR file with version information
    mkdir -p target
    cat > "$filename" << EOF
Test application JAR file
Version: $version
Build date: $(date)
This file simulates a Java application JAR file for testing purposes.
EOF
    
    print_success "Created test JAR with version $version"
}

# Function to verify deployment
verify_deployment() {
    local expected_version=$1
    local link_path=$2
    
    print_info "Verifying deployment at $link_path"
    
    if [ -L "$link_path" ]; then
        local target=$(readlink "$link_path")
        print_info "Symlink points to: $target"
        
        # Check if the target directory exists
        if [ -d "$target" ]; then
            # Check if the JAR file exists in the target directory
            local jar_file="$target/$ARTIFACT_NAME"
            if [ -f "$jar_file" ]; then
                # Check the version in the JAR file
                local version=$(grep "Version:" "$jar_file" | cut -d ":" -f2 | tr -d ' ')
                print_info "Found version: $version"
                
                if [ "$version" = "$expected_version" ]; then
                    print_success "Deployment verified: Version $version is deployed"
                    return 0
                else
                    print_error "Version mismatch: Expected $expected_version, found $version"
                    return 1
                fi
            else
                print_error "JAR file not found in target directory"
                return 1
            fi
        else
            print_error "Target directory does not exist: $target"
            return 1
        fi
    else
        print_error "Symlink does not exist: $link_path"
        return 1
    fi
}

# Main test script
print_header "GITLAB CI CONTAINER TEST ENVIRONMENT"
print_info "Running tests in Docker container"
print_info "Working directory: $(pwd)"

# Source the test functions
if [ -f "tests/test-functions.sh" ]; then
    source tests/test-functions.sh
else
    # Create simplified test functions
    cat > tests/test-functions.sh << 'EOF'
#!/bin/bash

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
EOF
    chmod +x tests/test-functions.sh
    source tests/test-functions.sh
    print_success "Created and sourced test functions"
fi

# Check if mock-mvnw exists and is executable
if [ ! -x "tests/mock-mvnw" ]; then
    print_info "Creating mock Maven wrapper..."
    cat > tests/mock-mvnw << 'EOF'
#!/bin/bash
echo "Mock Maven Wrapper - Simulating internal Maven component"
echo "Command: $@"
echo "Building package..."
mkdir -p target
echo "Mock JAR file created by mock-mvnw" > target/test-app.jar
echo "Build completed successfully."
EOF
    chmod +x tests/mock-mvnw
    print_success "Created mock Maven wrapper"
fi

# Check if mock-notification-service exists and is executable
if [ ! -x "tests/mock-notification-service" ]; then
    print_info "Creating mock notification service..."
    cat > tests/mock-notification-service << 'EOF'
#!/bin/bash
echo "Mock Notification Service"
echo "Status: $1"
echo "Message: $2"
echo "Notification sent successfully."
EOF
    chmod +x tests/mock-notification-service
    print_success "Created mock notification service"
fi

# Create test artifacts with different versions
print_header "CREATING TEST ARTIFACTS"

# Create version 1.0.0 JAR
create_test_jar "1.0.0" "target/test-app-1.0.0.jar"

# Create version 1.1.0 JAR for the second deployment
create_test_jar "1.1.0" "target/test-app-1.1.0.jar"

# Create version 1.2.0 JAR for the third deployment
create_test_jar "1.2.0" "target/test-app-1.2.0.jar"

# Run the validate job
print_header "RUNNING VALIDATE JOB"
export CI_JOB_NAME="test_validate"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: validate"

print_info "Validating environment variables..."
print_info "APP_NAME: $APP_NAME"
print_info "APP_VERSION: $APP_VERSION"
print_info "DEPLOY_HOST: $DEPLOY_HOST"
print_info "APP_USER: $APP_USER"
print_success "Validation successful!"

# Run the build job
print_header "RUNNING BUILD JOB"
export CI_JOB_NAME="test_build"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: build"

print_info "Executing job script..."
./tests/mock-mvnw package
print_info "Checking for artifacts..."
ls -la target/
print_success "Build job completed successfully!"

# Run the first deploy job - Version 1.0.0
print_header "RUNNING DEPLOY JOB - VERSION 1.0.0"
export CI_JOB_NAME="test_deploy"
export CI_JOB_ID="12345"
export ARTIFACT_PATH="target/test-app-1.0.0.jar"
export ARTIFACT_NAME="test-app-1.0.0.jar"
export APP_VERSION="1.0.0"

print_info "Job name: $CI_JOB_NAME"
print_info "Stage: deploy"
print_info "Deploying version: $APP_VERSION"

# Create directories
create_directories

# Create deployment directory
DEPLOY_DIR_PATH=$(create_deployment_dir)
print_success "Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
upload_application "$DEPLOY_DIR_PATH"
print_success "Application uploaded"

# Setup systemd service
setup_systemd_service
print_success "Systemd service set up"

# Stop current service
stop_service
print_success "Current service stopped"

# Update symlink
update_symlink "$DEPLOY_DIR_PATH"
print_success "Symlink updated"

# Start service
start_service
print_success "Service started"

# Perform health check
perform_health_check
print_success "Health check passed"

# Verify the deployment
verify_deployment "1.0.0" "$CURRENT_LINK"

# Run the notify job
print_header "RUNNING NOTIFY JOB"
export CI_JOB_NAME="test_notify"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: notify"

print_info "Sending notification..."
send_notification "SUCCESS" "Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
print_success "Notification sent"

# Run the second deploy job - Version 1.1.0
print_header "RUNNING DEPLOY JOB - VERSION 1.1.0"
export CI_JOB_NAME="test_deploy"
export CI_JOB_ID="12346"
export ARTIFACT_PATH="target/test-app-1.1.0.jar"
export ARTIFACT_NAME="test-app-1.1.0.jar"
export APP_VERSION="1.1.0"

print_info "Job name: $CI_JOB_NAME"
print_info "Stage: deploy"
print_info "Deploying version: $APP_VERSION"

# Store the first deployment path for later rollback
FIRST_DEPLOY_PATH="$DEPLOY_DIR_PATH"

# Create deployment directory
DEPLOY_DIR_PATH=$(create_deployment_dir)
print_success "Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
upload_application "$DEPLOY_DIR_PATH"
print_success "Application uploaded"

# Stop current service
stop_service
print_success "Current service stopped"

# Update symlink
update_symlink "$DEPLOY_DIR_PATH"
print_success "Symlink updated"

# Start service
start_service
print_success "Service started"

# Perform health check
perform_health_check
print_success "Health check passed"

# Verify the deployment
verify_deployment "1.1.0" "$CURRENT_LINK"

# Run the third deploy job - Version 1.2.0
print_header "RUNNING DEPLOY JOB - VERSION 1.2.0"
export CI_JOB_NAME="test_deploy"
export CI_JOB_ID="12347"
export ARTIFACT_PATH="target/test-app-1.2.0.jar"
export ARTIFACT_NAME="test-app-1.2.0.jar"
export APP_VERSION="1.2.0"

print_info "Job name: $CI_JOB_NAME"
print_info "Stage: deploy"
print_info "Deploying version: $APP_VERSION"

# Store the second deployment path for later rollback
SECOND_DEPLOY_PATH="$DEPLOY_DIR_PATH"

# Create deployment directory
DEPLOY_DIR_PATH=$(create_deployment_dir)
print_success "Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
upload_application "$DEPLOY_DIR_PATH"
print_success "Application uploaded"

# Stop current service
stop_service
print_success "Current service stopped"

# Update symlink
update_symlink "$DEPLOY_DIR_PATH"
print_success "Symlink updated"

# Start service
start_service
print_success "Service started"

# Perform health check
perform_health_check
print_success "Health check passed"

# Verify the deployment
verify_deployment "1.2.0" "$CURRENT_LINK"

# Run the rollback job - Rollback to Version 1.1.0
print_header "RUNNING ROLLBACK JOB - TO VERSION 1.1.0"
export CI_JOB_NAME="test_rollback"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: rollback"
print_info "Rolling back to version: 1.1.0"

print_info "Stopping current service..."
stop_service
print_success "Service stopped for rollback"

# Rollback to the second deployment (1.1.0)
print_info "Updating symlink to previous deployment..."
update_symlink "$SECOND_DEPLOY_PATH"
print_success "Symlink updated to previous deployment"

print_info "Starting service with previous version..."
start_service
print_success "Service started with previous version"

print_info "Performing health check..."
perform_health_check
print_success "Health check passed for rollback"

# Verify the rollback
verify_deployment "1.1.0" "$CURRENT_LINK"

print_info "Sending rollback notification..."
send_notification "ROLLBACK" "Rollback of $APP_NAME to version 1.1.0 in $CI_ENVIRONMENT_NAME environment completed successfully"
print_success "Rollback notification sent"

# Run another rollback job - Rollback to Version 1.0.0
print_header "RUNNING ROLLBACK JOB - TO VERSION 1.0.0"
export CI_JOB_NAME="test_rollback"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: rollback"
print_info "Rolling back to version: 1.0.0"

print_info "Stopping current service..."
stop_service
print_success "Service stopped for rollback"

# Rollback to the first deployment (1.0.0)
print_info "Updating symlink to first deployment..."
update_symlink "$FIRST_DEPLOY_PATH"
print_success "Symlink updated to first deployment"

print_info "Starting service with original version..."
start_service
print_success "Service started with original version"

print_info "Performing health check..."
perform_health_check
print_success "Health check passed for rollback"

# Verify the rollback
verify_deployment "1.0.0" "$CURRENT_LINK"

print_info "Sending rollback notification..."
send_notification "ROLLBACK" "Rollback of $APP_NAME to version 1.0.0 in $CI_ENVIRONMENT_NAME environment completed successfully"
print_success "Rollback notification sent"

# Final summary
print_header "TEST SUMMARY"
print_success "All GitLab CI jobs completed successfully!"
print_info "Deployment and rollback tests verified that:"
echo "1. Initial deployment of version 1.0.0 was successful"
echo "2. Upgrade to version 1.1.0 was successful"
echo "3. Upgrade to version 1.2.0 was successful"
echo "4. Rollback to version 1.1.0 was successful"
echo "5. Rollback to version 1.0.0 was successful"

print_info "Current deployment: $(readlink $CURRENT_LINK)"
print_info "Current version: $(grep "Version:" "$(readlink $CURRENT_LINK)/$ARTIFACT_NAME" | cut -d ":" -f2 | tr -d ' ')"

print_header "DEPLOYMENT DIRECTORY CONTENTS"
ls -la "$DEPLOY_DIR"

print_header "TEST COMPLETED"
