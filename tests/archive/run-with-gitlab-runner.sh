#!/bin/bash
# Run GitLab CI pipeline with GitLab Runner
# This script uses GitLab Runner to run the actual pipeline locally

set -e
echo "Running GitLab CI pipeline with GitLab Runner..."

# Check if GitLab Runner is installed
if ! command -v gitlab-runner &> /dev/null; then
    echo "❌ GitLab Runner is not installed. Please install GitLab Runner first."
    echo "   On macOS: brew install gitlab-runner"
    exit 1
fi

# Create a test directory
TEST_DIR="$(pwd)/tests/gitlab-runner-test"
mkdir -p "$TEST_DIR"

# Create a test GitLab CI configuration
echo "Creating test GitLab CI configuration..."
cat > "$TEST_DIR/.gitlab-ci.yml" << 'EOF'
# Test GitLab CI configuration for local testing with GitLab Runner

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
  - notify

build_job:
  stage: build
  script:
    - echo "Building application..."
    - mkdir -p target
    - echo "Mock JAR file" > target/test-app-1.0.0.jar
    - ls -la target/
    - echo "Build completed successfully."
  artifacts:
    paths:
      - target/*.jar

test_job:
  stage: test
  script:
    - echo "Testing application..."
    - test -f target/test-app-1.0.0.jar || (echo "Build artifact missing" && exit 1)
    - echo "Tests passed successfully."
  dependencies:
    - build_job

deploy_job:
  stage: deploy
  script:
    - echo "Deploying application..."
    - mkdir -p $DEPLOY_DIR $BACKUP_DIR $(dirname $CURRENT_LINK) $CONFIG_DIR $TMP_DIR
    - DEPLOY_DIR_PATH="$DEPLOY_DIR/$APP_NAME-$CI_JOB_ID"
    - mkdir -p $DEPLOY_DIR_PATH
    - cp target/$ARTIFACT_NAME $DEPLOY_DIR_PATH/
    - echo "Creating systemd service file..."
    - |
      cat > $CONFIG_DIR/test-app.service << EOT
      [Unit]
      Description=Test Application Service
      After=network.target
      
      [Service]
      Type=simple
      ExecStart=/bin/sh -c 'java -jar $CURRENT_LINK/test-app-1.0.0.jar'
      Restart=on-failure
      
      [Install]
      WantedBy=default.target
      EOT
    - echo "Stopping current service (simulated)..."
    - echo "Would execute: systemctl --user stop test-app.service"
    - echo "Updating symlink..."
    - ln -sfn $DEPLOY_DIR_PATH $CURRENT_LINK
    - echo "Starting service (simulated)..."
    - echo "Would execute: systemctl --user start test-app.service"
    - echo "Performing health check (simulated)..."
    - echo "Would execute: curl http://localhost:8080/health"
    - echo "Deployment completed successfully."
  dependencies:
    - build_job

notify_job:
  stage: notify
  script:
    - echo "Sending notification..."
    - echo "SUCCESS: Deployment of $APP_NAME version $APP_VERSION completed successfully"
    - echo "Notification sent successfully."
  dependencies:
    - deploy_job
EOF

# Create a mock Maven wrapper for the test
mkdir -p "$TEST_DIR/mvnw"
cp "$(pwd)/tests/mock-mvnw" "$TEST_DIR/mvnw" 2>/dev/null || echo "#!/bin/bash
echo 'Mock Maven Wrapper'
echo 'Building package...'
mkdir -p target
echo 'Mock JAR file' > target/test-app.jar
echo 'Build completed successfully.'
" > "$TEST_DIR/mvnw"
chmod +x "$TEST_DIR/mvnw"

# Create a script to run the pipeline with GitLab Runner
cat > "$TEST_DIR/run-pipeline.sh" << 'EOF'
#!/bin/bash
# Run GitLab CI pipeline with GitLab Runner

set -e
echo "Running GitLab CI pipeline with GitLab Runner..."

# Run the pipeline with GitLab Runner
echo "Running build job..."
gitlab-runner exec docker build_job --docker-privileged

echo "Running test job..."
gitlab-runner exec docker test_job --docker-privileged

echo "Running deploy job..."
gitlab-runner exec docker deploy_job --docker-privileged

echo "Running notify job..."
gitlab-runner exec docker notify_job --docker-privileged

echo "Pipeline execution completed!"
EOF

chmod +x "$TEST_DIR/run-pipeline.sh"

# Create a script to run the pipeline with GitLab Runner in shell mode
cat > "$TEST_DIR/run-pipeline-shell.sh" << 'EOF'
#!/bin/bash
# Run GitLab CI pipeline with GitLab Runner in shell mode

set -e
echo "Running GitLab CI pipeline with GitLab Runner in shell mode..."

# Run the pipeline with GitLab Runner
echo "Running build job..."
gitlab-runner exec shell build_job

echo "Running test job..."
gitlab-runner exec shell test_job

echo "Running deploy job..."
gitlab-runner exec shell deploy_job

echo "Running notify job..."
gitlab-runner exec shell notify_job

echo "Pipeline execution completed!"
EOF

chmod +x "$TEST_DIR/run-pipeline-shell.sh"

echo "GitLab Runner test environment setup completed!"
echo "To run the pipeline test with Docker, execute: cd $TEST_DIR && ./run-pipeline.sh"
echo "To run the pipeline test in shell mode, execute: cd $TEST_DIR && ./run-pipeline-shell.sh"
echo ""
echo "Note: The shell mode is faster but may not accurately simulate the GitLab CI environment."
echo "      The Docker mode is more accurate but requires Docker to be installed and running."
