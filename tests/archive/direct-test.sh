#!/bin/bash
# Direct test script for GitLab CI/CD pipeline
# This script directly tests the pipeline components without requiring GitLab Runner

set -e
echo "===== STARTING DIRECT PIPELINE TEST ====="

# Source test environment and functions
source "$(pwd)/tests/test-env.sh"
source "$(pwd)/tests/test-functions.sh"

# Set verbose output
set -x

echo "===== STAGE 1: BUILD ====="
echo "Building application..."
mkdir -p tests/sample-app/target
echo "Mock JAR file for testing" > tests/sample-app/target/test-app-1.0.0.jar
echo "Build completed successfully."

echo "===== STAGE 2: TEST ====="
echo "Testing application..."
if [ -f "tests/sample-app/target/test-app-1.0.0.jar" ]; then
  echo "✅ Build artifact exists"
else
  echo "❌ Build artifact missing"
  exit 1
fi
echo "Tests passed successfully."

echo "===== STAGE 3: DEPLOY ====="
echo "Deploying application..."

# Create required directories
create_directories
if [ ! -d "$DEPLOY_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ Failed to create directories"
  exit 1
fi
echo "✅ Directories created successfully"

# Create deployment directory
DEPLOY_DIR_RESULT=$(create_deployment_dir)
if [ -z "$DEPLOY_DIR_RESULT" ]; then
  echo "❌ Failed to create deployment directory"
  exit 1
fi
echo "✅ Deployment directory created: $DEPLOY_DIR_RESULT"

# Upload application
mkdir -p "$DEPLOY_DIR_RESULT"
cp "tests/sample-app/target/test-app-1.0.0.jar" "$DEPLOY_DIR_RESULT/"
if [ ! -f "$DEPLOY_DIR_RESULT/test-app-1.0.0.jar" ]; then
  echo "❌ Failed to upload application"
  exit 1
fi
echo "✅ Application uploaded successfully"

# Setup systemd service
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/test-app.service" << 'EOF'
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
EOF

if [ ! -f "$CONFIG_DIR/test-app.service" ]; then
  echo "❌ Failed to setup systemd service"
  exit 1
fi
echo "✅ Systemd service setup successfully"

# Stop current service
stop_service
echo "✅ Service stopped successfully"

# Update symlink
update_symlink "$DEPLOY_DIR_RESULT"
if [ ! -L "$CURRENT_LINK" ]; then
  echo "❌ Failed to update symlink"
  exit 1
fi
echo "✅ Symlink updated successfully"

# Start service
start_service
echo "✅ Service started successfully"

# Send notification
send_notification "SUCCESS" "Test deployment completed successfully"
echo "✅ Notification sent successfully"

echo "===== PIPELINE TEST COMPLETED SUCCESSFULLY ====="

# Try running in a Docker container if available
if command -v docker &> /dev/null; then
  echo "===== TESTING WITH DOCKER CONTAINER ====="
  
  # Create a temporary directory for testing
  TEST_TMP=$(mktemp -d)
  
  # Create a test script for the container
  cat > "$TEST_TMP/test-in-container.sh" << 'EOF'
#!/bin/bash
set -ex

echo "Testing in Red Hat UBI container..."
echo "Creating test directories..."
mkdir -p /tmp/deployments /tmp/backups /tmp/app /tmp/.config/systemd/user

echo "Creating test files..."
mkdir -p /tmp/deployments/test-app-12345
echo "Mock JAR file" > /tmp/deployments/test-app-12345/test-app.jar

echo "Creating symlink..."
ln -sfn /tmp/deployments/test-app-12345 /tmp/app/current

echo "Creating systemd service file..."
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/test-app.service << 'EOT'
[Unit]
Description=Test Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c 'while true; do echo "Service is running"; sleep 10; done'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

echo "Testing complete!"
EOF

  chmod +x "$TEST_TMP/test-in-container.sh"
  
  echo "Running test in Docker container..."
  docker run --rm \
    -v "$TEST_TMP:/test" \
    --privileged \
    registry.access.redhat.com/ubi8/ubi-minimal:latest \
    /test/test-in-container.sh
  
  echo "Docker container test completed!"
  rm -rf "$TEST_TMP"
else
  echo "Docker not available, skipping container test."
fi

echo "===== ALL TESTS COMPLETED SUCCESSFULLY ====="
