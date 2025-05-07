#!/bin/bash
# Setup script for gitlab-ci-local testing

set -e
echo "Setting up gitlab-ci-local for testing GitLab CI pipeline..."

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    echo "   On macOS: brew install node"
    exit 1
fi

# Install gitlab-ci-local
echo "Installing gitlab-ci-local..."
npm install -g gitlab-ci-local

# Create a test directory
TEST_DIR="$(pwd)/tests/gitlab-ci-local-test"
mkdir -p "$TEST_DIR"

# Create a simplified .gitlab-ci.yml for testing
echo "Creating test GitLab CI configuration..."
cat > "$TEST_DIR/.gitlab-ci.yml" << 'EOF'
# Test GitLab CI configuration for local testing with gitlab-ci-local

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

# Create a test script for running gitlab-ci-local
echo "Creating test script..."
cat > "$TEST_DIR/run-gitlab-ci-local.sh" << 'EOF'
#!/bin/bash
# Run GitLab CI pipeline with gitlab-ci-local

set -e
echo "Running GitLab CI pipeline with gitlab-ci-local..."

# Check if gitlab-ci-local is installed
if ! command -v gitlab-ci-local &> /dev/null; then
    echo "❌ gitlab-ci-local is not installed. Please run the setup script first."
    exit 1
fi

# Run the pipeline with verbose output
echo "Running pipeline with verbose output..."
gitlab-ci-local --verbose .gitlab-ci.yml

echo "Pipeline execution completed!"
EOF

chmod +x "$TEST_DIR/run-gitlab-ci-local.sh"

# Create a mock Maven wrapper for the test
mkdir -p "$TEST_DIR/mvnw"
cp "$(pwd)/tests/mock-mvnw" "$TEST_DIR/mvnw"
chmod +x "$TEST_DIR/mvnw"

echo "gitlab-ci-local setup completed!"
echo "To run the pipeline test, execute: cd $TEST_DIR && ./run-gitlab-ci-local.sh"
echo ""
echo "Note: You can modify the .gitlab-ci.yml file in $TEST_DIR to test different configurations."
echo "      The verbose output option is enabled by default."
