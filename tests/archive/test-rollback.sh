#!/bin/bash
# Test script to simulate a rollback process

set -e
echo "Starting rollback test..."

# Source test environment and functions
source "$(pwd)/tests/test-env.sh"
source "$(pwd)/tests/test-functions.sh"

# Create multiple test deployment directories to simulate rollback scenario
TEST_JAR_DIR="$(pwd)/tests/sample-app/target"
mkdir -p "$TEST_JAR_DIR"

# Create first deployment (older)
FIRST_DEPLOY_DIR="$DEPLOY_DIR/test-app-12344"
mkdir -p "$FIRST_DEPLOY_DIR"
echo "This is the first deployment JAR file" > "$FIRST_DEPLOY_DIR/test-app.jar"

# Create second deployment (current)
CURRENT_DEPLOY_DIR="$DEPLOY_DIR/test-app-12345"
mkdir -p "$CURRENT_DEPLOY_DIR"
echo "This is the current deployment JAR file" > "$CURRENT_DEPLOY_DIR/test-app.jar"

# Set up the current symlink to point to the current deployment
mkdir -p "$(dirname "$CURRENT_LINK")"
ln -sfn "$CURRENT_DEPLOY_DIR" "$CURRENT_LINK"

echo "Test environment prepared with multiple deployments:"
echo "- First deployment: $FIRST_DEPLOY_DIR"
echo "- Current deployment: $CURRENT_DEPLOY_DIR"
echo "- Current symlink points to: $(readlink "$CURRENT_LINK")"
echo ""

echo "Step 1: Identifying rollback target..."
# In a real scenario, this would be determined by the rollback strategy
ROLLBACK_TARGET="$FIRST_DEPLOY_DIR"
echo "✅ Rollback target identified: $ROLLBACK_TARGET"

echo "Step 2: Stopping current service..."
stop_service
echo "✅ Current service stopped"

echo "Step 3: Updating symlink to rollback target..."
update_symlink "$ROLLBACK_TARGET"
if [ "$(readlink "$CURRENT_LINK")" != "$ROLLBACK_TARGET" ]; then
  echo "❌ Failed to update symlink for rollback"
  exit 1
fi
echo "✅ Symlink updated to rollback target"

echo "Step 4: Starting service with rollback version..."
start_service
echo "✅ Service started with rollback version"

echo "Step 5: Performing health check on rollback version..."
perform_health_check
echo "✅ Health check passed on rollback version"

echo "Step 6: Sending rollback notification..."
send_notification "ROLLBACK" "Rollback completed successfully to previous version"
echo "✅ Rollback notification sent"

echo "All rollback steps completed successfully! 🎉"
echo "Current deployment is now: $(readlink "$CURRENT_LINK")"
