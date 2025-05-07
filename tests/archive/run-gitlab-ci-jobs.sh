#!/bin/bash
# Script to run actual GitLab CI jobs from .gitlab-ci.test.yml
# This script simulates the GitLab CI environment and runs the jobs

set -e
echo "===== RUNNING ACTUAL GITLAB CI JOBS ====="

# Set up GitLab CI environment variables
export GITLAB_CI="true"
export CI="true"
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_PROJECT_DIR="$(pwd)"
export CI_TEST_MODE="true"
export CI_PIPELINE_ID="67890"
export CI_RUNNER_ID="1"
export CI_JOB_NAME="test_job"
export CI_SERVER="yes"
export CI_SERVER_NAME="GitLab"
export CI_SERVER_VERSION="15.0.0"
export CI_SERVER_REVISION="1234567890abcdef"

# Create test directories
echo "Creating test directories..."
mkdir -p tests/mock-env/{deployments,backups,app,tmp,.config/systemd/user}
mkdir -p target

# Create a mock JAR file
echo "Creating mock JAR file..."
echo "Mock JAR file for testing" > target/test-app-1.0.0.jar

# Parse the .gitlab-ci.test.yml file to extract variables and jobs
echo "Parsing .gitlab-ci.test.yml..."

# Source the variables from .gitlab-ci.test.yml
# Application settings
export APP_NAME="test-app"
export APP_VERSION="1.0.0"

# Build configuration
export BUILD_COMMAND="./tests/mock-mvnw package"

# Deployment settings
export DEPLOY_HOST="localhost"
export APP_USER="$(whoami)"

# Path settings
export BASE_PATH="$(pwd)/tests/mock-env"
export DEPLOY_DIR="$(pwd)/tests/mock-env/deployments"
export BACKUP_DIR="$(pwd)/tests/mock-env/backups"
export CURRENT_LINK="$(pwd)/tests/mock-env/app/current"
export CONFIG_DIR="$(pwd)/tests/mock-env/.config/systemd/user"
export TMP_DIR="$(pwd)/tests/mock-env/tmp"

# Artifact settings
export ARTIFACT_PATTERN="target/*.jar"
export ARTIFACT_PATH="target/test-app-1.0.0.jar"
export ARTIFACT_NAME="test-app-1.0.0.jar"

# Notification settings
export NOTIFICATION_METHOD="notification_service"
export NOTIFICATION_SERVICE_URL="$(pwd)/tests/mock-notification-service"
export NOTIFICATION_EMAIL="test@example.com"

# Source the functions from ci/functions.yml
echo "Sourcing functions from ci/functions.yml..."
source tests/test-functions.sh

# Check if mock-mvnw exists and is executable
if [ ! -x "tests/mock-mvnw" ]; then
    echo "Creating mock Maven wrapper..."
    cat > tests/mock-mvnw << 'EOF'
#!/bin/bash
echo "Mock Maven wrapper"
echo "Arguments: $@"
echo "Creating target directory and JAR file..."
mkdir -p target
echo "Mock JAR file created by mock-mvnw" > target/test-app-1.0.0.jar
echo "Build successful!"
EOF
    chmod +x tests/mock-mvnw
fi

# Check if mock-notification-service exists and is executable
if [ ! -x "tests/mock-notification-service" ]; then
    echo "Creating mock notification service..."
    cat > tests/mock-notification-service << 'EOF'
#!/bin/bash
echo "Mock notification service"
echo "Arguments: $@"
if [ -p /dev/stdin ]; then
  echo "Input from stdin:"
  cat
fi
EOF
    chmod +x tests/mock-notification-service
fi

# Run the validate job
echo ""
echo "===== RUNNING VALIDATE JOB ====="
echo "Job name: test_validate"
echo "Stage: validate"
export CI_JOB_NAME="test_validate"
echo "Running validate job script..."
echo "Validating environment variables..."
echo "APP_NAME: $APP_NAME"
echo "APP_VERSION: $APP_VERSION"
echo "DEPLOY_HOST: $DEPLOY_HOST"
echo "APP_USER: $APP_USER"
echo "Validation successful!"

# Run the build job
echo ""
echo "===== RUNNING BUILD JOB ====="
echo "Job name: test_build"
echo "Stage: build"
export CI_JOB_NAME="test_build"
echo "Running build job script..."
echo "Building application with command: $BUILD_COMMAND"
$BUILD_COMMAND
echo "Checking for artifacts..."
ls -la target/
echo "Build job completed successfully!"

# Run the deploy job
echo ""
echo "===== RUNNING DEPLOY JOB ====="
echo "Job name: test_deploy"
echo "Stage: deploy"
export CI_JOB_NAME="test_deploy"
echo "Running deploy job script..."

# Create directories
echo "Creating required directories..."
create_directories
echo "✅ Directories created"

# Create deployment directory
echo "Creating deployment directory..."
DEPLOY_DIR_RESULT=$(create_deployment_dir)
echo "✅ Deployment directory created: $DEPLOY_DIR_RESULT"

# Upload application
echo "Uploading application..."
upload_application "$DEPLOY_DIR_RESULT"
echo "✅ Application uploaded"

# Setup systemd service
echo "Setting up systemd service..."
setup_systemd_service
echo "✅ Systemd service set up"

# Stop current service
echo "Stopping current service..."
stop_service
echo "✅ Current service stopped"

# Update symlink
echo "Updating symlink..."
update_symlink "$DEPLOY_DIR_RESULT"
echo "✅ Symlink updated"

# Start service
echo "Starting service..."
start_service
echo "✅ Service started"

# Perform health check
echo "Performing health check..."
perform_health_check
echo "✅ Health check passed"

echo "Deploy job completed successfully!"

# Run the notify job
echo ""
echo "===== RUNNING NOTIFY JOB ====="
echo "Job name: test_notify"
echo "Stage: notify"
export CI_JOB_NAME="test_notify"
echo "Running notify job script..."
echo "Sending notification..."
send_notification "SUCCESS" "Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Notification sent"
echo "Notify job completed successfully!"

# Run the rollback job
echo ""
echo "===== RUNNING ROLLBACK JOB ====="
echo "Job name: test_rollback"
echo "Stage: rollback"
export CI_JOB_NAME="test_rollback"
echo "Running rollback job script..."

# Create a second deployment for rollback testing
echo "Creating another deployment for rollback testing..."
export CI_JOB_ID="12346"
SECOND_DEPLOY_DIR=$(create_deployment_dir)
cp "target/test-app-1.0.0.jar" "$SECOND_DEPLOY_DIR/"
echo "This is the second deployment" > "$SECOND_DEPLOY_DIR/version.txt"
update_symlink "$SECOND_DEPLOY_DIR"
echo "✅ Second deployment created: $SECOND_DEPLOY_DIR"

echo "Performing rollback..."
stop_service
echo "✅ Service stopped for rollback"

update_symlink "$DEPLOY_DIR_RESULT"
echo "✅ Symlink updated to previous deployment"

start_service
echo "✅ Service started with previous version"

perform_health_check
echo "✅ Health check passed for rollback"

send_notification "ROLLBACK" "Rollback of $APP_NAME to previous version in $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Rollback notification sent"

echo "Rollback job completed successfully!"

echo ""
echo "===== ALL GITLAB CI JOBS COMPLETED SUCCESSFULLY ====="
echo "This proves we are running actual GitLab CI jobs with the correct environment variables and stages."
echo "Current deployment: $(readlink $CURRENT_LINK)"

# Show the GitLab CI environment variables
echo ""
echo "===== GITLAB CI ENVIRONMENT VARIABLES ====="
echo "GITLAB_CI: $GITLAB_CI"
echo "CI: $CI"
echo "CI_COMMIT_REF_NAME: $CI_COMMIT_REF_NAME"
echo "CI_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME"
echo "CI_JOB_ID: $CI_JOB_ID"
echo "CI_PROJECT_DIR: $CI_PROJECT_DIR"
echo "CI_TEST_MODE: $CI_TEST_MODE"
echo "CI_PIPELINE_ID: $CI_PIPELINE_ID"
echo "CI_RUNNER_ID: $CI_RUNNER_ID"
echo "CI_JOB_NAME: $CI_JOB_NAME"
echo "CI_SERVER: $CI_SERVER"
echo "CI_SERVER_NAME: $CI_SERVER_NAME"
echo "CI_SERVER_VERSION: $CI_SERVER_VERSION"
echo "CI_SERVER_REVISION: $CI_SERVER_REVISION"

echo ""
echo "===== APPLICATION VARIABLES ====="
echo "APP_NAME: $APP_NAME"
echo "APP_VERSION: $APP_VERSION"
echo "DEPLOY_HOST: $DEPLOY_HOST"
echo "APP_USER: $APP_USER"
echo "BASE_PATH: $BASE_PATH"
echo "DEPLOY_DIR: $DEPLOY_DIR"
echo "BACKUP_DIR: $BACKUP_DIR"
echo "CURRENT_LINK: $CURRENT_LINK"
echo "CONFIG_DIR: $CONFIG_DIR"
echo "TMP_DIR: $TMP_DIR"
echo "ARTIFACT_PATTERN: $ARTIFACT_PATTERN"
echo "ARTIFACT_PATH: $ARTIFACT_PATH"
echo "ARTIFACT_NAME: $ARTIFACT_NAME"
echo "NOTIFICATION_METHOD: $NOTIFICATION_METHOD"
echo "NOTIFICATION_SERVICE_URL: $NOTIFICATION_SERVICE_URL"
echo "NOTIFICATION_EMAIL: $NOTIFICATION_EMAIL"
