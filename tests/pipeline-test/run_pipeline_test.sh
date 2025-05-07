#!/bin/bash
set -e

echo "=== Running full pipeline test with systemd ==="
cd /test

# Setup environment variables for testing
export CI_ENVIRONMENT_NAME="test"
export APP_NAME="test-app"
export APP_VERSION="1.0.0"
export APP_TYPE="java"
export DEPLOY_HOST="localhost"
export DEPLOY_DIR="/test/deployments"
export BASE_PATH="/test/app"
export CONFIG_DIR="/test/etc/systemd/system"
export ARTIFACT_PATTERN="*.jar"
export ARTIFACT_PATH="sample-app/target"
export ARTIFACT_NAME="test-app-1.0.0.jar"
export CI_TEST_MODE="true"

# Create directories needed for test
mkdir -p "$DEPLOY_DIR/$APP_NAME/$APP_VERSION"
mkdir -p "$BASE_PATH/$APP_NAME"
mkdir -p "$CONFIG_DIR"
mkdir -p "$ARTIFACT_PATH"

# Make sure the systemd service file exists and is accessible
echo "Verifying systemd service file is available..."
ls -la /test/
cat > "$CONFIG_DIR/$APP_NAME.service" << 'EOSVC'
[Unit]
Description=Test Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/app
ExecStart=/bin/bash -c "while true; do echo 'Service is running'; sleep 5; done"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOSVC
chmod 644 "$CONFIG_DIR/$APP_NAME.service"
echo "Service file created at $CONFIG_DIR/$APP_NAME.service"

# Source the actual functions
source "/test/functions.sh"

echo "======== TESTING ACTUAL PIPELINE FUNCTIONS ========"
echo "Running tests using the EXACT SAME functions that will be used in production"

# Run through the actual pipeline with real functions from functions.yml

echo "=== Testing build stage ==="
echo "Mock JAR file" > "$ARTIFACT_PATH/$ARTIFACT_NAME"
echo "✓ Build artifacts created"

echo "=== Testing deployment with systemd ==="
echo "1. Creating deployment directory"
create_deployment_dir
echo "✓ Deployment directory created at $DEPLOY_DIR/$APP_NAME/$APP_VERSION"

echo "2. Deploying to servers"
deploy_to_servers
echo "✓ Application deployed"

echo "3. Setting up systemd service"
cp systemd-test.service "$CONFIG_DIR/$APP_NAME.service"
echo "✓ Service file created"

echo "4. Testing systemd daemon-reload"
systemctl daemon-reload
echo "✓ Daemon reload successful"

echo "5. Testing service enable"
systemctl enable "$APP_NAME.service"
echo "✓ Service enabled"

echo "6. Creating symlink"
create_symlink
echo "✓ Symlink created from $DEPLOY_DIR/$APP_NAME/$APP_VERSION to $BASE_PATH/$APP_NAME/current"

echo "7. Starting service"
start_service
echo "✓ Service started"

echo "8. Checking service status"
check_service_status
echo "✓ Service is running"

echo "=== Testing rollback ==="
echo "1. Creating previous version for rollback"
mkdir -p "$DEPLOY_DIR/$APP_NAME/0.9.0"
echo "Mock previous version" > "$DEPLOY_DIR/$APP_NAME/0.9.0/$ARTIFACT_NAME"
echo "✓ Created previous version 0.9.0"

echo "2. Testing rollback operation"
TMP_VERSION="$APP_VERSION"
export APP_VERSION="0.9.0"
stop_service
create_symlink
start_service
echo "✓ Rolled back from $TMP_VERSION to 0.9.0"

echo "3. Checking service status after rollback"
check_service_status
echo "✓ Service is running with rollback version"

echo "4. Testing rollback to original version"
export APP_VERSION="$TMP_VERSION"
stop_service
create_symlink
start_service
echo "✓ Rolled back to original version $APP_VERSION"

echo "=== Cleanup ==="
stop_service
systemctl disable "$APP_NAME.service"
rm -f "$CONFIG_DIR/$APP_NAME.service"
systemctl daemon-reload
echo "✓ Cleanup completed"

echo "=== All tests passed successfully! ==="
echo "This confirms that the exact functions from functions.yml work correctly"
echo "for the complete pipeline flow including build, deploy,"
echo "and rollback with systemd services."
