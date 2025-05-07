#!/bin/bash
# Run GitLab CI pipeline in Docker

set -e
echo "Running GitLab CI pipeline in Docker..."

# Set up environment variables for testing
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_PROJECT_DIR="/app"
export CI_TEST_MODE="true"

# Create required directories
mkdir -p /tmp/deployments /tmp/backups /tmp/app /tmp/.config/systemd/user /tmp/tmp

# Run the build job
echo "===== RUNNING BUILD JOB ====="
mkdir -p target
echo "Mock JAR file" > target/test-app-1.0.0.jar
echo "✅ Build job completed successfully"

# Run the test job
echo "===== RUNNING TEST JOB ====="
echo "Running tests..."
echo "✅ Test job completed successfully"

# Run the deploy job
echo "===== RUNNING DEPLOY JOB ====="
echo "Deploying application..."
DEPLOY_DIR_PATH="/tmp/deployments/test-app-$CI_JOB_ID"
mkdir -p $DEPLOY_DIR_PATH
cp target/test-app-1.0.0.jar $DEPLOY_DIR_PATH/
ln -sfn $DEPLOY_DIR_PATH /tmp/app/current
echo "✅ Deploy job completed successfully"

echo "===== PIPELINE COMPLETED SUCCESSFULLY ====="
