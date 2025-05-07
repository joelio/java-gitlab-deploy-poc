#!/bin/bash
# Test GitLab CI pipeline with Docker
# This script uses Docker to test the GitLab CI pipeline in a containerized environment

set -e
echo "Testing GitLab CI pipeline with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Create a test directory for the pipeline
TEST_DIR="$(pwd)/tests/pipeline-test"
mkdir -p "$TEST_DIR"

echo "Creating test GitLab CI configuration..."
cat > "$TEST_DIR/.gitlab-ci.yml" << 'EOF'
# Test GitLab CI configuration for local testing

variables:
  # Test mode enabled
  CI_TEST_MODE: "true"
  
  # Application settings
  APP_NAME: "test-app"
  APP_VERSION: "1.0.0"
  
  # Build configuration
  BUILD_COMMAND: "./mvnw package"
  
  # Path settings
  DEPLOY_DIR: "/tmp/deployments"
  BACKUP_DIR: "/tmp/backups"
  CURRENT_LINK: "/tmp/app/current"
  CONFIG_DIR: "/tmp/.config/systemd/user"
  TMP_DIR: "/tmp/tmp"
  
  # Artifact settings
  ARTIFACT_PATTERN: "target/*.jar"
  ARTIFACT_NAME: "test-app-1.0.0.jar"
  
  # Notification settings
  NOTIFICATION_METHOD: "notification_service"
  NOTIFICATION_SERVICE_URL: "/bin/echo"

stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  image: maven:3.8-openjdk-11
  script:
    - echo "Building application..."
    - mkdir -p target
    - echo "Mock JAR file" > target/test-app-1.0.0.jar
    - echo "Build completed successfully."
  artifacts:
    paths:
      - target/*.jar

test_job:
  stage: test
  image: maven:3.8-openjdk-11
  script:
    - echo "Testing application..."
    - echo "Tests passed successfully."
  dependencies:
    - build_job

deploy_job:
  stage: deploy
  image: registry.access.redhat.com/ubi8/ubi-minimal:latest
  script:
    - echo "Deploying application..."
    - mkdir -p $DEPLOY_DIR $BACKUP_DIR $(dirname $CURRENT_LINK) $CONFIG_DIR $TMP_DIR
    - DEPLOY_DIR_PATH="$DEPLOY_DIR/$APP_NAME-$CI_JOB_ID"
    - mkdir -p $DEPLOY_DIR_PATH
    - cp target/$ARTIFACT_NAME $DEPLOY_DIR_PATH/
    - ln -sfn $DEPLOY_DIR_PATH $CURRENT_LINK
    - echo "Deployment completed successfully."
  dependencies:
    - build_job
EOF

echo "Creating test script to run the pipeline..."
cat > "$TEST_DIR/run-pipeline.sh" << 'EOF'
#!/bin/bash
# Run GitLab CI pipeline in Docker container

set -e

# Create a temporary directory for the pipeline
TEMP_DIR=$(mktemp -d)
cp .gitlab-ci.yml $TEMP_DIR/

# Run the pipeline in a Docker container
echo "Running GitLab CI pipeline in Docker container..."
docker run --rm \
  -v $TEMP_DIR:/ci \
  -w /ci \
  registry.gitlab.com/gitlab-org/gitlab-runner:latest \
  gitlab-runner exec docker --docker-privileged build_job

docker run --rm \
  -v $TEMP_DIR:/ci \
  -w /ci \
  registry.gitlab.com/gitlab-org/gitlab-runner:latest \
  gitlab-runner exec docker --docker-privileged test_job

docker run --rm \
  -v $TEMP_DIR:/ci \
  -w /ci \
  registry.gitlab.com/gitlab-org/gitlab-runner:latest \
  gitlab-runner exec docker --docker-privileged deploy_job

echo "Pipeline execution completed!"
EOF

# Make the run script executable
chmod +x "$TEST_DIR/run-pipeline.sh"

echo "Test environment created at $TEST_DIR"
echo "To run the pipeline test, execute: cd $TEST_DIR && ./run-pipeline.sh"

# Create a systemd service test script
echo "Creating systemd service test script..."
cat > "$TEST_DIR/test-systemd.sh" << 'EOF'
#!/bin/bash
# Test systemd service in a Docker container

set -e
echo "Testing systemd service in Docker container..."

# Create a test service file
cat > test-service.service << 'EOT'
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

# Run a container with systemd
echo "Starting container with systemd..."
CONTAINER_ID=$(docker run -d --rm \
  --name systemd-test \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  registry.access.redhat.com/ubi8/ubi:latest \
  /sbin/init)

echo "Container started with ID: $CONTAINER_ID"

# Copy the service file to the container
docker cp test-service.service systemd-test:/etc/systemd/system/

# Enable and start the service
echo "Enabling and starting the service..."
docker exec systemd-test systemctl daemon-reload
docker exec systemd-test systemctl enable test-service
docker exec systemd-test systemctl start test-service

# Check the service status
echo "Checking service status..."
docker exec systemd-test systemctl status test-service

# Clean up
echo "Press Enter to stop the container and clean up..."
read
docker stop systemd-test
echo "Test completed and container stopped."
EOF

chmod +x "$TEST_DIR/test-systemd.sh"

echo "Testing environment setup completed!"
echo "Available test scripts:"
echo "1. $TEST_DIR/run-pipeline.sh - Test GitLab CI pipeline with Docker"
echo "2. $TEST_DIR/test-systemd.sh - Test systemd service with Docker"
echo ""
echo "Note: These tests require Docker to be installed and running."
