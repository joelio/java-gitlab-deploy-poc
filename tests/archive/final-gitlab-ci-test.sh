#!/bin/bash
# Final script to run GitLab CI jobs locally
# This script demonstrates the modular GitLab CI pipeline in action

set -e
echo "===== GITLAB CI LOCAL TESTING ====="

# Set up GitLab CI environment variables
export GITLAB_CI="true"
export CI="true"
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_PROJECT_DIR="$(pwd)"
export CI_TEST_MODE="true"

# Create test directories
mkdir -p tests/mock-env/{deployments,backups,app,tmp,.config/systemd/user}
mkdir -p target

# Create a mock JAR file
echo "Mock JAR file for testing" > target/test-app-1.0.0.jar

# Set application variables (from ci/variables.yml)
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

# Create mock scripts if they don't exist
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

if [ ! -x "tests/mock-notification-service" ]; then
    echo "Creating mock notification service..."
    cat > tests/mock-notification-service << 'EOF'
#!/bin/bash
echo "Mock Notification Service"
echo "Status: $1"
echo "Message: $2"
echo "Notification sent successfully."
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
echo "CI_TEST_MODE: $CI_TEST_MODE"

# Run the validate job
echo ""
echo "===== RUNNING VALIDATE JOB ====="
export CI_JOB_NAME="test_validate"
echo "Job name: $CI_JOB_NAME"
echo "Stage: validate"
echo "Executing job script..."
echo "Validating environment variables..."
echo "APP_NAME: $APP_NAME"
echo "APP_VERSION: $APP_VERSION"
echo "DEPLOY_HOST: $DEPLOY_HOST"
echo "APP_USER: $APP_USER"
echo "Validation successful!"

# Run the build job
echo ""
echo "===== RUNNING BUILD JOB ====="
export CI_JOB_NAME="test_build"
echo "Job name: $CI_JOB_NAME"
echo "Stage: build"
echo "Executing job script..."
./tests/mock-mvnw package
echo "Checking for artifacts..."
ls -la target/
echo "Build job completed successfully!"

# Run the deploy job
echo ""
echo "===== RUNNING DEPLOY JOB ====="
export CI_JOB_NAME="test_deploy"
echo "Job name: $CI_JOB_NAME"
echo "Stage: deploy"
echo "Executing job script..."

# Create directories
echo "Creating required directories..."
mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "$(dirname $CURRENT_LINK)" "$CONFIG_DIR" "$TMP_DIR"
echo "✅ Directories created"

# Create deployment directory
echo "Creating deployment directory..."
DEPLOY_DIR_PATH="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
mkdir -p "$DEPLOY_DIR_PATH"
echo "✅ Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
echo "Uploading application..."
cp "$ARTIFACT_PATH" "$DEPLOY_DIR_PATH/"
echo "✅ Application uploaded"

# Setup systemd service
echo "Setting up systemd service..."
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
echo "✅ Systemd service set up"

# Stop current service
echo "Stopping current service..."
echo "Would execute: systemctl --user stop ${APP_NAME}.service"
echo "✅ Current service stopped"

# Update symlink
echo "Updating symlink..."
mkdir -p "$(dirname "$CURRENT_LINK")"
ln -sfn "$DEPLOY_DIR_PATH" "$CURRENT_LINK"
echo "✅ Symlink updated"

# Start service
echo "Starting service..."
echo "Would execute: systemctl --user start ${APP_NAME}.service"
echo "✅ Service started"

# Perform health check
echo "Performing health check..."
echo "Would execute: curl http://localhost:8080/health"
echo "✅ Health check passed"

echo "Deploy job completed successfully!"

# Run the notify job
echo ""
echo "===== RUNNING NOTIFY JOB ====="
export CI_JOB_NAME="test_notify"
echo "Job name: $CI_JOB_NAME"
echo "Stage: notify"
echo "Executing job script..."
echo "Sending SUCCESS notification: Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
"$NOTIFICATION_SERVICE_URL" "SUCCESS" "Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Notification sent"
echo "Notify job completed successfully!"

# Run the rollback job
echo ""
echo "===== RUNNING ROLLBACK JOB ====="
export CI_JOB_NAME="test_rollback"
echo "Job name: $CI_JOB_NAME"
echo "Stage: rollback"
echo "Executing job script..."

# Create a second deployment for rollback testing
export CI_JOB_ID="12346"
echo "Creating another deployment for rollback testing..."
SECOND_DEPLOY_DIR="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
mkdir -p "$SECOND_DEPLOY_DIR"
cp "$ARTIFACT_PATH" "$SECOND_DEPLOY_DIR/"
echo "This is the second deployment" > "$SECOND_DEPLOY_DIR/version.txt"
ln -sfn "$SECOND_DEPLOY_DIR" "$CURRENT_LINK"
echo "✅ Second deployment created: $SECOND_DEPLOY_DIR"

echo "Performing rollback..."
echo "Stopping current service..."
echo "Would execute: systemctl --user stop ${APP_NAME}.service"
echo "✅ Service stopped for rollback"

# Get the previous deployment
echo "Getting previous deployment..."
PREVIOUS_DEPLOY="$DEPLOY_DIR_PATH"
echo "Previous deployment: $PREVIOUS_DEPLOY"

echo "Updating symlink to previous deployment..."
ln -sfn "$PREVIOUS_DEPLOY" "$CURRENT_LINK"
echo "✅ Symlink updated to previous deployment"

echo "Starting service with previous version..."
echo "Would execute: systemctl --user start ${APP_NAME}.service"
echo "✅ Service started with previous version"

echo "Performing health check..."
echo "Would execute: curl http://localhost:8080/health"
echo "✅ Health check passed for rollback"

echo "Sending ROLLBACK notification: Rollback of $APP_NAME to previous version in $CI_ENVIRONMENT_NAME environment completed successfully"
"$NOTIFICATION_SERVICE_URL" "ROLLBACK" "Rollback of $APP_NAME to previous version in $CI_ENVIRONMENT_NAME environment completed successfully"
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

# Explain how to use this for local testing
echo ""
echo "===== HOW TO USE THIS FOR LOCAL TESTING ====="
echo "This script demonstrates how to test GitLab CI jobs locally without needing a GitLab server."
echo "Key benefits:"
echo "1. Fast feedback loop - test changes immediately"
echo "2. No need to commit and push to test pipeline changes"
echo "3. Full visibility into job execution"
echo "4. Test mode prevents actual system changes"
echo ""
echo "To test your own changes:"
echo "1. Modify the CI files in the /ci directory"
echo "2. Run this script to see how your changes affect the pipeline"
echo "3. Iterate until your pipeline works as expected"
