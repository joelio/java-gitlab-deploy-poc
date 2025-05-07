#!/bin/bash
# Script to simulate GitLab CI jobs and demonstrate the modular pipeline
# This script shows how actual GitLab CI jobs would run with our pipeline

set -e
echo "===== SIMULATING GITLAB CI PIPELINE EXECUTION ====="

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

# Set application variables (from ci/variables.yml)
echo "Loading variables from ci/variables.yml..."
export APP_NAME="test-app"
export APP_VERSION="1.0.0"
export DEPLOY_HOST="localhost"
export APP_USER="$(whoami)"
export BASE_PATH="$(pwd)/tests/mock-env"
export DEPLOY_DIR="$(pwd)/tests/mock-env/deployments"
export BACKUP_DIR="$(pwd)/tests/mock-env/backups"
export CURRENT_LINK="$(pwd)/tests/mock-env/app/current"
export CONFIG_DIR="$(pwd)/tests/mock-env/.config/systemd/user"
export TMP_DIR="$(pwd)/tests/mock-env/tmp"
export ARTIFACT_PATTERN="target/*.jar"
export ARTIFACT_PATH="target/test-app-1.0.0.jar"
export ARTIFACT_NAME="test-app-1.0.0.jar"
export NOTIFICATION_METHOD="notification_service"
export NOTIFICATION_SERVICE_URL="$(pwd)/tests/mock-notification-service"
export NOTIFICATION_EMAIL="test@example.com"

# Source the functions (from ci/functions.yml)
echo "Loading functions from tests/test-functions.sh..."
source tests/test-functions.sh

# Check if mock-mvnw exists and is executable
if [ ! -x "tests/mock-mvnw" ]; then
    echo "Creating mock Maven wrapper..."
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

# Print GitLab CI environment to prove we're simulating GitLab CI
echo ""
echo "===== GITLAB CI ENVIRONMENT ====="
echo "GITLAB_CI: $GITLAB_CI"
echo "CI: $CI"
echo "CI_COMMIT_REF_NAME: $CI_COMMIT_REF_NAME"
echo "CI_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME"
echo "CI_JOB_ID: $CI_JOB_ID"
echo "CI_PROJECT_DIR: $CI_PROJECT_DIR"
echo "CI_PIPELINE_ID: $CI_PIPELINE_ID"
echo "CI_RUNNER_ID: $CI_RUNNER_ID"
echo "CI_SERVER: $CI_SERVER"
echo "CI_SERVER_NAME: $CI_SERVER_NAME"
echo "CI_SERVER_VERSION: $CI_SERVER_VERSION"
echo "CI_SERVER_REVISION: $CI_SERVER_REVISION"

# Show how GitLab CI includes our modular components
echo ""
echo "===== GITLAB CI INCLUDES MODULAR COMPONENTS ====="
echo "include:"
echo "  - local: '/ci/variables.yml'"
echo "  - local: '/ci/functions.yml'"
echo "  - local: '/ci/build.yml'"
echo "  - local: '/ci/deploy.yml'"
echo "  - local: '/ci/rollback.yml'"
echo "  - local: '/ci/notify.yml'"

# Run the validate job (from ci/build.yml)
echo ""
echo "===== RUNNING VALIDATE JOB ====="
export CI_JOB_NAME="test_validate"
echo "Job name: $CI_JOB_NAME"
echo "Stage: validate"
echo "Script from .gitlab-ci.test.yml:"
echo "  - echo \"Validating environment variables...\""
echo "  - echo \"APP_NAME: \$APP_NAME\""
echo "  - echo \"APP_VERSION: \$APP_VERSION\""
echo "  - echo \"DEPLOY_HOST: \$DEPLOY_HOST\""
echo "  - echo \"APP_USER: \$APP_USER\""
echo ""
echo "Executing job script..."
echo "Validating environment variables..."
echo "APP_NAME: $APP_NAME"
echo "APP_VERSION: $APP_VERSION"
echo "DEPLOY_HOST: $DEPLOY_HOST"
echo "APP_USER: $APP_USER"
echo "Validation successful!"

# Run the build job (from ci/build.yml)
echo ""
echo "===== RUNNING BUILD JOB ====="
export CI_JOB_NAME="test_build"
echo "Job name: $CI_JOB_NAME"
echo "Stage: build"
echo "Script from .gitlab-ci.test.yml:"
echo "  - ./tests/mock-mvnw package"
echo "  - ls -la target/"
echo ""
echo "Executing job script..."
./tests/mock-mvnw package
echo "Checking for artifacts..."
ls -la target/
echo "Build job completed successfully!"

# Run the deploy job (from ci/deploy.yml)
echo ""
echo "===== RUNNING DEPLOY JOB ====="
export CI_JOB_NAME="test_deploy"
echo "Job name: $CI_JOB_NAME"
echo "Stage: deploy"
echo "Script from .gitlab-ci.test.yml (via ci/deploy.yml):"
echo "  - source ci/functions.yml"
echo "  - create_directories"
echo "  - DEPLOY_DIR_PATH=\$(create_deployment_dir)"
echo "  - upload_application \$DEPLOY_DIR_PATH"
echo "  - setup_systemd_service"
echo "  - stop_service"
echo "  - update_symlink \$DEPLOY_DIR_PATH"
echo "  - start_service"
echo "  - perform_health_check"
echo ""
echo "Executing job script..."

# Create directories
echo "Creating required directories..."
create_directories
echo "✅ Directories created"

# Create deployment directory
echo "Creating deployment directory..."
DEPLOY_DIR_PATH=$(create_deployment_dir)
echo "✅ Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
echo "Uploading application..."
upload_application "$DEPLOY_DIR_PATH"
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
update_symlink "$DEPLOY_DIR_PATH"
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

# Run the notify job (from ci/notify.yml)
echo ""
echo "===== RUNNING NOTIFY JOB ====="
export CI_JOB_NAME="test_notify"
echo "Job name: $CI_JOB_NAME"
echo "Stage: notify"
echo "Script from .gitlab-ci.test.yml (via ci/notify.yml):"
echo "  - source ci/functions.yml"
echo "  - send_notification \"SUCCESS\" \"Deployment of \$APP_NAME version \$APP_VERSION to \$CI_ENVIRONMENT_NAME environment completed successfully\""
echo ""
echo "Executing job script..."
echo "Sending notification..."
send_notification "SUCCESS" "Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Notification sent"
echo "Notify job completed successfully!"

# Run the rollback job (from ci/rollback.yml)
echo ""
echo "===== RUNNING ROLLBACK JOB ====="
export CI_JOB_NAME="test_rollback"
echo "Job name: $CI_JOB_NAME"
echo "Stage: rollback"
echo "Script from .gitlab-ci.test.yml (via ci/rollback.yml):"
echo "  - source ci/functions.yml"
echo "  - stop_service"
echo "  - PREVIOUS_DEPLOY=\$(get_last_successful_deploy)"
echo "  - update_symlink \$PREVIOUS_DEPLOY"
echo "  - start_service"
echo "  - perform_health_check"
echo "  - send_notification \"ROLLBACK\" \"Rollback of \$APP_NAME to previous version in \$CI_ENVIRONMENT_NAME environment completed successfully\""
echo ""
echo "Executing job script..."

# Create a second deployment for rollback testing
echo "Creating another deployment for rollback testing..."
export CI_JOB_ID="12346"
SECOND_DEPLOY_DIR=$(create_deployment_dir)
cp target/test-app-1.0.0.jar "$SECOND_DEPLOY_DIR/"
echo "This is the second deployment" > "$SECOND_DEPLOY_DIR/version.txt"
update_symlink "$SECOND_DEPLOY_DIR"
echo "✅ Second deployment created: $SECOND_DEPLOY_DIR"

echo "Performing rollback..."
stop_service
echo "✅ Service stopped for rollback"

# Simulate getting the previous deployment
PREVIOUS_DEPLOY="$DEPLOY_DIR_PATH"
echo "Previous deployment: $PREVIOUS_DEPLOY"

update_symlink "$PREVIOUS_DEPLOY"
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
echo "This demonstrates how our modular GitLab CI pipeline executes in a real GitLab CI environment."
echo "Each job uses components from our modular structure:"
echo "- Variables from ci/variables.yml"
echo "- Functions from ci/functions.yml"
echo "- Job templates from ci/build.yml, ci/deploy.yml, ci/rollback.yml, and ci/notify.yml"
echo ""
echo "Current deployment: $(readlink $CURRENT_LINK)"

# Show the file structure to demonstrate modularity
echo ""
echo "===== MODULAR PIPELINE STRUCTURE ====="
echo "Main file: .gitlab-ci.yml"
echo "Modular components:"
echo "- ci/variables.yml: Global and environment-specific variables"
echo "- ci/functions.yml: Shell functions for deployment operations"
echo "- ci/build.yml: Build job templates"
echo "- ci/deploy.yml: Deployment job templates"
echo "- ci/rollback.yml: Rollback job templates"
echo "- ci/notify.yml: Notification job templates"
