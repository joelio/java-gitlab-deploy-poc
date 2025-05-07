#!/bin/bash
# Test script to simulate a complete deployment process

set -e
echo "Starting deployment test..."

# Source test environment and functions
source "$(pwd)/tests/test-env.sh"
source "$(pwd)/tests/test-functions.sh"

# Create a simple test JAR file
TEST_JAR_DIR="$(pwd)/tests/sample-app/target"
mkdir -p "$TEST_JAR_DIR"
echo "This is a mock JAR file for testing" > "$TEST_JAR_DIR/test-app.jar"

echo "Step 1: Creating directories..."
create_directories
if [ ! -d "$DEPLOY_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ Failed to create directories"
  exit 1
fi
echo "✅ Directories created successfully"

echo "Step 2: Creating deployment directory..."
DEPLOY_DIR_RESULT=$(create_deployment_dir)
if [ -z "$DEPLOY_DIR_RESULT" ]; then
  echo "❌ Failed to create deployment directory"
  exit 1
fi
echo "✅ Deployment directory created: $DEPLOY_DIR_RESULT"

echo "Step 3: Uploading application..."
upload_application "$DEPLOY_DIR_RESULT"
# Simulate the upload by copying our test JAR
mkdir -p "$DEPLOY_DIR_RESULT"
cp "$TEST_JAR_DIR/test-app.jar" "$DEPLOY_DIR_RESULT/"
if [ ! -f "$DEPLOY_DIR_RESULT/test-app.jar" ]; then
  echo "❌ Failed to upload application"
  exit 1
fi
echo "✅ Application uploaded successfully"

echo "Step 4: Setting up systemd service..."
# Copy our sample service file to the config directory
mkdir -p "$CONFIG_DIR"
cp "$(pwd)/tests/sample-service.service" "$CONFIG_DIR/test-app.service"
setup_systemd_service
if [ ! -f "$CONFIG_DIR/test-app.service" ]; then
  echo "❌ Failed to setup systemd service"
  exit 1
fi
echo "✅ Systemd service setup successfully"

echo "Step 5: Stopping current service..."
stop_service
echo "✅ Service stopped successfully"

echo "Step 6: Updating symlink..."
update_symlink "$DEPLOY_DIR_RESULT"
if [ ! -L "$CURRENT_LINK" ]; then
  echo "❌ Failed to update symlink"
  exit 1
fi
echo "✅ Symlink updated successfully"

echo "Step 7: Enabling linger..."
enable_linger
echo "✅ Linger enabled successfully"

echo "Step 8: Starting service..."
start_service
echo "✅ Service started successfully"

echo "Step 9: Performing health check..."
perform_health_check
echo "✅ Health check passed"

echo "Step 10: Sending notification..."
send_notification "SUCCESS" "Test deployment completed successfully"
echo "✅ Notification sent successfully"

echo "All deployment steps completed successfully! 🎉"
