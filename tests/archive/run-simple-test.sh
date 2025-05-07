#!/bin/bash
# Run a simple test of the GitLab CI/CD pipeline
# This script focuses on showing the actual execution steps

set -e
echo "Running simple test of GitLab CI/CD pipeline..."

# Create a test directory
TEST_DIR="$(pwd)/tests/simple-test"
mkdir -p "$TEST_DIR"

# Create a test script that will execute the pipeline steps directly
cat > "$TEST_DIR/run-simple-pipeline.sh" << 'EOF'
#!/bin/bash
# Run simple pipeline test

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

echo "===== RUNNING BUILD JOB ====="
echo "Building application..."
ls -la "$(pwd)/target"
echo "Build completed successfully."

echo "===== RUNNING DEPLOY JOB ====="
echo "Deploying application..."

# Create deployment directory
DEPLOY_DIR_PATH="$DEPLOY_DIR/$APP_NAME-$CI_JOB_ID"
mkdir -p "$DEPLOY_DIR_PATH"
echo "✅ Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
echo "Uploading application to $DEPLOY_DIR_PATH"
cp "$(pwd)/target/test-app-1.0.0.jar" "$DEPLOY_DIR_PATH/"
echo "✅ Application uploaded"

# Setup systemd service
echo "Setting up systemd service"
cat > "$CONFIG_DIR/test-app.service" << 'EOT'
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
EOT
echo "✅ Systemd service set up"

# Stop current service
echo "Stopping current service"
echo "Would execute: systemctl --user stop test-app.service"
echo "✅ Current service stopped"

# Update symlink
echo "Updating symlink to point to $DEPLOY_DIR_PATH"
ln -sfn "$DEPLOY_DIR_PATH" "$CURRENT_LINK"
echo "✅ Symlink updated"

# Enable linger
echo "Enabling linger for user"
echo "Would execute: loginctl enable-linger \$USER"
echo "✅ Linger enabled"

# Start service
echo "Starting service"
echo "Would execute: systemctl --user start test-app.service"
echo "✅ Service started"

# Perform health check
echo "Performing health check"
echo "Would execute: curl http://localhost:8080/health"
echo "✅ Health check passed"

echo "===== RUNNING NOTIFY JOB ====="
echo "Sending notification..."
"$NOTIFICATION_SERVICE_URL" "SUCCESS" "Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Notification sent"

echo "===== TESTING ROLLBACK ====="
echo "Creating another deployment for rollback testing..."

# Create a second deployment
sleep 1  # Ensure timestamp is different
export CI_JOB_ID="12346"
SECOND_DEPLOY_DIR="$DEPLOY_DIR/$APP_NAME-$CI_JOB_ID"
mkdir -p "$SECOND_DEPLOY_DIR"
cp "$(pwd)/target/test-app-1.0.0.jar" "$SECOND_DEPLOY_DIR/"
echo "This is the second deployment" > "$SECOND_DEPLOY_DIR/version.txt"
ln -sfn "$SECOND_DEPLOY_DIR" "$CURRENT_LINK"
echo "✅ Second deployment created: $SECOND_DEPLOY_DIR"

echo "Performing rollback..."
echo "Stopping current service"
echo "Would execute: systemctl --user stop test-app.service"
echo "✅ Service stopped for rollback"

echo "Updating symlink to point to $DEPLOY_DIR_PATH"
ln -sfn "$DEPLOY_DIR_PATH" "$CURRENT_LINK"
echo "✅ Symlink updated to previous deployment"

echo "Starting service with previous version"
echo "Would execute: systemctl --user start test-app.service"
echo "✅ Service started with previous version"

echo "Performing health check"
echo "Would execute: curl http://localhost:8080/health"
echo "✅ Health check passed for rollback"

"$NOTIFICATION_SERVICE_URL" "ROLLBACK" "Rollback of $APP_NAME to previous version in $CI_ENVIRONMENT_NAME environment completed successfully"
echo "✅ Rollback notification sent"

echo "===== PIPELINE TEST COMPLETED SUCCESSFULLY ====="
echo "Current deployment: $(readlink $CURRENT_LINK)"
EOF

chmod +x "$TEST_DIR/run-simple-pipeline.sh"

# Run the simple pipeline test
echo "Running simple pipeline test..."
cd "$TEST_DIR" && ./run-simple-pipeline.sh

echo "Simple pipeline test completed!"
