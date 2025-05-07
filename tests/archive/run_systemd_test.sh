#!/bin/bash
# Real container-based test for systemd functionality
# This script builds and runs a privileged container that can use systemd
# to test the actual systemd service handling in the pipeline

set -e

REPO_ROOT="/Users/joel/src/gitlab-ci-refactor"
TESTS_DIR="$REPO_ROOT/tests"
DOCKERFILE="$TESTS_DIR/Dockerfile.systemd"
TEST_SCRIPT="$TESTS_DIR/test_in_container.sh"
CONTAINER_NAME="gitlab-ci-systemd-test"

echo "=== Building and running a real systemd container test ==="

# Make sure the test script exists and is executable
cat > "$TEST_SCRIPT" << 'EOF'
#!/bin/bash
# This script runs inside the container to test systemd functionality

set -e

echo "=== Running systemd tests inside container ==="

# Variables for testing
APP_NAME="test-app"
CONFIG_DIR="/etc/systemd/system"
DEPLOY_DIR="/tmp/deployments"
BACKUP_DIR="/tmp/backups"
BASE_PATH="/tmp/app"
CURRENT_LINK="$BASE_PATH/current"

echo "1. Creating test service file"
cat > "$CONFIG_DIR/$APP_NAME.service" << SERVICE
[Unit]
Description=Test Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/tmp
ExecStart=/bin/bash -c "while true; do echo 'Service is running'; sleep 5; done"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

echo "2. Testing systemd daemon-reload"
systemctl daemon-reload
echo "✓ systemctl daemon-reload succeeded"

echo "3. Testing service enable"
systemctl enable "$APP_NAME.service"
if systemctl is-enabled "$APP_NAME.service"; then
  echo "✓ Service was successfully enabled"
else
  echo "✗ Failed to enable service"
  exit 1
fi

echo "4. Testing service start"
systemctl start "$APP_NAME.service"
sleep 2
if systemctl is-active "$APP_NAME.service"; then
  echo "✓ Service was successfully started"
else
  echo "✗ Failed to start service"
  exit 1
fi

echo "5. Testing service status"
systemctl status "$APP_NAME.service"
echo "✓ Status command succeeded"

echo "6. Testing service stop"
systemctl stop "$APP_NAME.service"
sleep 2
if ! systemctl is-active "$APP_NAME.service" &>/dev/null; then
  echo "✓ Service was successfully stopped"
else
  echo "✗ Failed to stop service"
  exit 1
fi

echo "=== All systemd tests passed successfully! ==="
EOF

chmod +x "$TEST_SCRIPT"

# Build the container with systemd
echo "Building systemd-capable container image..."
docker build -t "$CONTAINER_NAME" -f "$DOCKERFILE" "$REPO_ROOT"

# Run the container with systemd enabled
echo "Running container with systemd support..."
docker run --rm --name "$CONTAINER_NAME-instance" \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v "$TEST_SCRIPT:/test.sh" \
  "$CONTAINER_NAME" \
  /bin/bash -c "/test.sh"

echo "=== Systemd container test completed ==="
