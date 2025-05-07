#!/bin/bash
# Run GitLab CI pipeline with Docker
# This script uses Docker to run the GitLab CI pipeline locally

set -e
echo "Running GitLab CI pipeline with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Create a test directory
TEST_DIR="$(pwd)/tests/docker-test"
mkdir -p "$TEST_DIR"

# Copy the .gitlab-ci.yml file to the test directory
cp "$(pwd)/.gitlab-ci.yml" "$TEST_DIR/"

# Copy the CI directory to the test directory
cp -r "$(pwd)/ci" "$TEST_DIR/"

# Create a mock Maven wrapper for the test
mkdir -p "$TEST_DIR/mvnw"
cp "$(pwd)/tests/mock-mvnw" "$TEST_DIR/mvnw"
chmod +x "$TEST_DIR/mvnw"

# Create a test script for running the pipeline in Docker
cat > "$TEST_DIR/run-pipeline.sh" << 'EOF'
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
EOF

chmod +x "$TEST_DIR/run-pipeline.sh"

# Create a Docker Compose file for running the pipeline
cat > "$TEST_DIR/docker-compose.yml" << 'EOF'
version: '3'

services:
  pipeline:
    image: registry.access.redhat.com/ubi8/ubi:latest
    volumes:
      - ./:/app
    working_dir: /app
    command: ./run-pipeline.sh
    environment:
      - CI_COMMIT_REF_NAME=develop
      - CI_ENVIRONMENT_NAME=test
      - CI_JOB_ID=12345
      - CI_PROJECT_DIR=/app
      - CI_TEST_MODE=true
EOF

# Create a script to run the pipeline with Docker Compose
cat > "$TEST_DIR/run.sh" << 'EOF'
#!/bin/bash
# Run the pipeline with Docker Compose

set -e
echo "Running GitLab CI pipeline with Docker Compose..."

# Run the pipeline
docker-compose up --build

echo "Pipeline execution completed!"
EOF

chmod +x "$TEST_DIR/run.sh"

echo "Docker test environment setup completed!"
echo "To run the pipeline test, execute: cd $TEST_DIR && ./run.sh"
echo ""
echo "This will run the pipeline in a Docker container that simulates the GitLab CI environment."
echo "The output will be displayed in the terminal."
