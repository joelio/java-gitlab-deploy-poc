#!/bin/bash
# Run a detailed test of the GitLab CI/CD pipeline
# This script shows the actual execution of the pipeline components

set -e
echo "Running detailed test of GitLab CI/CD pipeline..."

# Create a test directory
TEST_DIR="$(pwd)/tests/detailed-test-fixed"
mkdir -p "$TEST_DIR"

# Copy the test functions to the test directory
cp "$(pwd)/tests/test-functions.sh" "$TEST_DIR/"

# Create a test script that will execute the actual pipeline components
cat > "$TEST_DIR/run-detailed-pipeline.sh" << 'EOF'
#!/bin/bash
# Run detailed pipeline test

set -e
set -x  # Enable command echo for detailed output

echo "===== SETTING UP TEST ENVIRONMENT ====="

# Set up environment variables for testing
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_PROJECT_DIR="$(pwd)"
export CI_TEST_MODE="true"

# Application settings
export APP_NAME="test-app"
export APP_VERSION="1.0.0"

# Path settings
export BASE_PATH="$(pwd)/mock-env"
export DEPLOY_DIR="$(pwd)/mock-env/deployments"
export BACKUP_DIR="$(pwd)/mock-env/backups"
export CURRENT_LINK="$(pwd)/mock-env/app/current"
export CONFIG_DIR="$(pwd)/mock-env/.config/systemd/user"
export TMP_DIR="$(pwd)/mock-env/tmp"

# Artifact settings
export ARTIFACT_PATTERN="target/*.jar"
export ARTIFACT_PATH="target/test-app-1.0.0.jar"
export ARTIFACT_NAME="test-app-1.0.0.jar"

# Notification settings
export NOTIFICATION_METHOD="notification_service"
export NOTIFICATION_SERVICE_URL="$(pwd)/mock-notification-service"
export NOTIFICATION_EMAIL="test@example.com"

# Create required directories
mkdir -p "$DEPLOY_DIR" "$BACKUP_DIR" "$(dirname $CURRENT_LINK)" "$CONFIG_DIR" "$TMP_DIR"

# Create a mock notification service
cat > "$(pwd)/mock-notification-service" << 'EOT'
#!/bin/bash
echo "NOTIFICATION SERVICE CALLED:"
echo "Arguments: $@"
if [ -p /dev/stdin ]; then
  echo "Input from stdin:"
  cat
fi
EOT
chmod +x "$(pwd)/mock-notification-service"

# Create a sample app directory with a mock JAR
mkdir -p "$(pwd)/target"
echo "Mock JAR file for testing" > "$(pwd)/target/test-app-1.0.0.jar"

echo "===== SOURCING TEST FUNCTIONS ====="
source ./test-functions.sh

echo "===== RUNNING BUILD JOB ====="
echo "Building application..."
ls -la "$(pwd)/target"
echo "Build completed successfully."

echo "===== RUNNING DEPLOY JOB ====="
echo "Deploying application..."

# Create directories
create_directories
echo "✅ Directories created"

# Backup current deployment (if exists)
if [ -L "$CURRENT_LINK" ]; then
  backup_current_deployment
  echo "✅ Current deployment backed up"
fi

# Create deployment directory
DEPLOY_DIR_RESULT=$(create_deployment_dir)
echo "✅ Deployment directory created: $DEPLOY_DIR_RESULT"

# Upload application
upload_application "$DEPLOY_DIR_RESULT"
# Manually copy the JAR since we're in test mode
cp "$(pwd)/target/test-app-1.0.0.jar" "$DEPLOY_DIR_RESULT/"
echo "✅ Application uploaded"

# Setup systemd service
setup_systemd_service
echo "✅ Systemd service set up"

# Stop current service
stop_service
echo "✅ Current service stopped"

# Update symlink
update_symlink "$DEPLOY_DIR_RESULT"
echo "✅ Symlink updated"

# Enable linger
enable_linger
echo "✅ Linger enabled"

# Start service
start_service
echo "✅ Service started"

# Perform health check
perform_health_check
echo "✅ Health check passed"

echo "===== RUNNING NOTIFY JOB ====="
echo "Sending notification..."
send_notification "SUCCESS" "Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Notification sent"

echo "===== TESTING ROLLBACK ====="
echo "Creating another deployment for rollback testing..."

# Create a second deployment
sleep 1  # Ensure timestamp is different
export CI_JOB_ID="12346"
SECOND_DEPLOY_DIR=$(create_deployment_dir)
cp "$(pwd)/target/test-app-1.0.0.jar" "$SECOND_DEPLOY_DIR/"
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

echo "===== PIPELINE TEST COMPLETED SUCCESSFULLY ====="
echo "Current deployment: $(readlink $CURRENT_LINK)"
EOF

chmod +x "$TEST_DIR/run-detailed-pipeline.sh"

# Run the detailed pipeline test
echo "Running detailed pipeline test..."
cd "$TEST_DIR" && ./run-detailed-pipeline.sh

echo "Detailed pipeline test completed!"
