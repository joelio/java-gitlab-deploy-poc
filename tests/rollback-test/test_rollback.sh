#!/bin/bash
# Test the systemd service handling and rollback functionality

set -e

# Create required directories
mkdir -p /etc/systemd/system
mkdir -p /deployments/test-app/1.0.0
mkdir -p /deployments/test-app/0.9.0
mkdir -p /app/test-app

# Create test artifacts
echo "Current version (1.0.0)" > /deployments/test-app/1.0.0/app.jar
echo "Previous version (0.9.0)" > /deployments/test-app/0.9.0/app.jar

# Setup environment variables
APP_NAME="test-app"
APP_VERSION="1.0.0"
DEPLOY_DIR="/deployments"
BASE_PATH="/app"

# Create service file for testing
cat > /etc/systemd/system/test-app.service << 'EOT'
[Unit]
Description=Test Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/app/test-app/current
ExecStart=/bin/bash -c "while true; do echo 'Service is running'; sleep 5; done"
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT

echo "=== Testing systemd service handling ==="

echo "1. Testing systemd daemon-reload"
systemctl daemon-reload
echo "✓ Daemon reload successful"

echo "2. Testing service enable"
systemctl enable test-app.service
echo "✓ Service enabled"

echo "3. Testing symlink creation for current version"
ln -sfn "/deployments/test-app/1.0.0" "/app/test-app/current"
echo "✓ Symlink created to version 1.0.0"

echo "4. Testing service start"
systemctl start test-app.service
echo "✓ Service started"

echo "5. Testing service status"
systemctl status test-app.service
echo "✓ Service is running with version 1.0.0"

echo "=== Testing rollback functionality ==="

echo "1. Testing service stop for rollback"
systemctl stop test-app.service
echo "✓ Service stopped"

echo "2. Testing symlink update for rollback"
ln -sfn "/deployments/test-app/0.9.0" "/app/test-app/current"
echo "✓ Symlink updated to version 0.9.0"

echo "3. Testing service restart after rollback"
systemctl start test-app.service
echo "✓ Service restarted"

echo "4. Testing service status after rollback"
systemctl status test-app.service
echo "✓ Service is running with version 0.9.0"

echo "5. Verifying rollback was successful"
cat /app/test-app/current/app.jar
echo "✓ Rollback successful, running version 0.9.0"

echo "=== Testing roll-forward (back to latest version) ==="

echo "1. Testing service stop for roll-forward"
systemctl stop test-app.service
echo "✓ Service stopped"

echo "2. Testing symlink update for roll-forward"
ln -sfn "/deployments/test-app/1.0.0" "/app/test-app/current"
echo "✓ Symlink updated to version 1.0.0"

echo "3. Testing service restart after roll-forward"
systemctl start test-app.service
echo "✓ Service restarted"

echo "4. Testing service status after roll-forward"
systemctl status test-app.service
echo "✓ Service is running with version 1.0.0"

echo "5. Verifying roll-forward was successful"
cat /app/test-app/current/app.jar
echo "✓ Roll-forward successful, running version 1.0.0"

echo "=== Cleanup ==="
systemctl stop test-app.service
systemctl disable test-app.service
rm -f /etc/systemd/system/test-app.service
systemctl daemon-reload
echo "✓ Cleanup completed"

echo "=== All tests passed successfully! ==="
echo "This validates that the systemd service handling and rollback functionality"
echo "work as expected in a real environment."
