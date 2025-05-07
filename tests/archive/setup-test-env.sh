#!/bin/bash
# Setup script for local testing environment
# This script prepares the environment for testing the GitLab CI/CD pipeline

set -e
echo "Setting up local test environment..."

# Create test directories
TEST_DIR="$(pwd)/tests"
MOCK_DIR="$TEST_DIR/mock-env"

# Create mock environment structure
mkdir -p "$MOCK_DIR/app"
mkdir -p "$MOCK_DIR/deployments"
mkdir -p "$MOCK_DIR/backups"
mkdir -p "$MOCK_DIR/.config/systemd/user"
mkdir -p "$MOCK_DIR/tmp"

# Create a sample Java application for testing
SAMPLE_APP_DIR="$TEST_DIR/sample-app"
mkdir -p "$SAMPLE_APP_DIR/src/main/java/com/example"

# Create a simple Java application
cat > "$SAMPLE_APP_DIR/src/main/java/com/example/TestApp.java" << 'EOF'
package com.example;

public class TestApp {
    public static void main(String[] args) {
        System.out.println("Test application is running!");
    }
}
EOF

# Create a simple pom.xml
cat > "$SAMPLE_APP_DIR/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>test-app</artifactId>
    <version>1.0.0</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.2.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.example.TestApp</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Copy our mock scripts to the sample app directory
cp "$TEST_DIR/mock-mvnw" "$SAMPLE_APP_DIR/mvnw"
chmod +x "$SAMPLE_APP_DIR/mvnw"

# Create a mock .gitlab-ci.yml for testing
cat > "$TEST_DIR/.gitlab-ci.test.yml" << 'EOF'
# Test version of .gitlab-ci.yml with mock components

variables:
  # Test mode enabled
  CI_TEST_MODE: "true"
  
  # Application settings
  APP_NAME: "test-app"
  APP_VERSION: "1.0.0"
  
  # Build configuration
  BUILD_COMMAND: "./mvnw package"
  
  # Deployment settings
  DEPLOY_HOST: "localhost"
  APP_USER: "$(whoami)"
  
  # Path settings
  BASE_PATH: "$(pwd)/tests/mock-env"
  DEPLOY_DIR: "$(pwd)/tests/mock-env/deployments"
  BACKUP_DIR: "$(pwd)/tests/mock-env/backups"
  CURRENT_LINK: "$(pwd)/tests/mock-env/app/current"
  CONFIG_DIR: "$(pwd)/tests/mock-env/.config/systemd/user"
  TMP_DIR: "$(pwd)/tests/mock-env/tmp"
  
  # Artifact settings
  ARTIFACT_PATTERN: "target/*.jar"
  ARTIFACT_PATH: "target/test-app-1.0.0.jar"
  ARTIFACT_NAME: "test-app-1.0.0.jar"
  
  # Notification settings
  NOTIFICATION_METHOD: "notification_service"
  NOTIFICATION_SERVICE_URL: "$(pwd)/tests/mock-notification-service"
  NOTIFICATION_EMAIL: "test@example.com"

include:
  - local: '/ci/variables.yml'
  - local: '/ci/functions.yml'
  - local: '/ci/build.yml'
  - local: '/ci/deploy.yml'
  - local: '/ci/rollback.yml'
  - local: '/ci/notify.yml'

stages:
  - validate
  - build
  - deploy
  - notify
  - rollback

# Test jobs
test_validate:
  stage: validate
  script:
    - echo "Running validation test..."
    - echo "Validation successful!"

test_build:
  stage: build
  script:
    - cd tests/sample-app
    - $BUILD_COMMAND
    - mkdir -p target
    - echo "Mock JAR file for testing" > target/test-app-1.0.0.jar
    - echo "Build successful!"
  artifacts:
    paths:
      - tests/sample-app/target/*.jar

test_deploy:
  stage: deploy
  script:
    - echo "Running deployment test..."
    - source ci/functions.yml
    - create_directories
    - create_deployment_dir
    - echo "Deployment successful!"
  needs:
    - test_build

test_notify:
  stage: notify
  script:
    - echo "Running notification test..."
    - source ci/functions.yml
    - send_notification "SUCCESS" "Test deployment successful"
    - echo "Notification successful!"
  needs:
    - test_deploy

test_rollback:
  stage: rollback
  script:
    - echo "Running rollback test..."
    - source ci/functions.yml
    - echo "Rollback successful!"
  when: manual
EOF

echo "Creating test environment variables file..."
cat > "$TEST_DIR/test-env.sh" << 'EOF'
#!/bin/bash
# Environment variables for local testing

# Set GitLab CI variables for testing
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_PROJECT_DIR="$(pwd)"

# Set test mode
export CI_TEST_MODE="true"

# Set paths for testing
export APP_NAME="test-app"
export APP_VERSION="1.0.0"
export DEPLOY_HOST="localhost"
export APP_USER="$(whoami)"
export BASE_PATH="$(pwd)/tests/mock-env"
export DEPLOY_DIR="$(pwd)/tests/mock-env/deployments"
export BACKUP_DIR="$(pwd)/tests/mock-env/backups"
export CURRENT_LINK="$(pwd)/tests/mock-env/app/current"
export CONFIG_DIR="$(pwd)/tests/mock-env/.config/systemd/user"
export TMP_DIR="$(pwd)/tests/mock-env/tmp"

# Set artifact settings
export ARTIFACT_PATTERN="target/*.jar"
export ARTIFACT_PATH="target/test-app-1.0.0.jar"
export ARTIFACT_NAME="test-app-1.0.0.jar"

# Set notification settings
export NOTIFICATION_METHOD="notification_service"
export NOTIFICATION_SERVICE_URL="$(pwd)/tests/mock-notification-service"
export NOTIFICATION_EMAIL="test@example.com"

echo "Test environment variables set."
EOF

chmod +x "$TEST_DIR/test-env.sh"

echo "Creating test runner script..."
cat > "$TEST_DIR/run-tests.sh" << 'EOF'
#!/bin/bash
# Script to run local tests for the GitLab CI/CD pipeline

set -e
echo "Running local tests for GitLab CI/CD pipeline..."

# Source test environment variables
source "$(pwd)/tests/test-env.sh"

# Function to run a test
run_test() {
  local test_name=$1
  local test_script=$2
  
  echo "========================================"
  echo "Running test: $test_name"
  echo "========================================"
  
  # Run the test script
  bash -c "$test_script"
  
  if [ $? -eq 0 ]; then
    echo "✅ Test '$test_name' passed!"
  else
    echo "❌ Test '$test_name' failed!"
    exit 1
  fi
  
  echo ""
}

# Test 1: Validate pipeline syntax
run_test "Pipeline Syntax Validation" "
  if command -v gitlab-runner &> /dev/null; then
    gitlab-runner exec lint .gitlab-ci.yml
  else
    echo 'GitLab Runner not installed. Skipping syntax validation.'
    echo 'To install: brew install gitlab-runner'
  fi
"

# Test 2: Test functions.yml
run_test "Functions Script" "
  source ci/functions.yml
  
  # Test log function
  log 'INFO' 'Testing log function'
  
  # Test is_test_mode function
  if is_test_mode; then
    echo 'Test mode is enabled'
  else
    echo 'Test mode is disabled'
    exit 1
  fi
  
  # Test create_directories function
  create_directories
  if [ -d '$DEPLOY_DIR' ] && [ -d '$BACKUP_DIR' ]; then
    echo 'Directories created successfully'
  else
    echo 'Failed to create directories'
    exit 1
  fi
  
  # Test create_deployment_dir function
  DEPLOY_DIR_RESULT=\$(create_deployment_dir)
  if [ -n \"\$DEPLOY_DIR_RESULT\" ]; then
    echo \"Deployment directory created: \$DEPLOY_DIR_RESULT\"
  else
    echo 'Failed to create deployment directory'
    exit 1
  fi
"

# Test 3: Test build process
run_test "Build Process" "
  cd tests/sample-app
  ./mvnw package
  if [ -f 'target/test-app.jar' ]; then
    echo 'Build successful'
  else
    echo 'Build failed'
    exit 1
  fi
  cd ../..
"

# Test 4: Test deployment process
run_test "Deployment Process" "
  source ci/functions.yml
  
  # Create a test deployment
  create_directories
  DEPLOY_DIR_RESULT=\$(create_deployment_dir)
  echo \"Mock JAR file\" > tests/sample-app/target/test-app.jar
  upload_application \"\$DEPLOY_DIR_RESULT\"
  setup_systemd_service
  update_symlink \"\$DEPLOY_DIR_RESULT\"
  
  # Verify deployment
  if [ -L '$CURRENT_LINK' ]; then
    echo 'Deployment successful'
  else
    echo 'Deployment failed'
    exit 1
  fi
"

# Test 5: Test notification
run_test "Notification Process" "
  source ci/functions.yml
  
  # Test notification
  send_notification 'SUCCESS' 'Test notification'
  
  echo 'Notification test completed'
"

echo "All tests completed successfully! 🎉"
EOF

chmod +x "$TEST_DIR/run-tests.sh"

echo "Creating cleanup script..."
cat > "$TEST_DIR/cleanup.sh" << 'EOF'
#!/bin/bash
# Script to clean up test environment

echo "Cleaning up test environment..."

# Remove test directories
rm -rf "$(pwd)/tests/mock-env"
rm -rf "$(pwd)/tests/sample-app/target"

echo "Test environment cleaned up."
EOF

chmod +x "$TEST_DIR/cleanup.sh"

echo "Test environment setup completed successfully!"
echo "To run tests, execute: ./tests/run-tests.sh"
echo "To clean up after testing, execute: ./tests/cleanup.sh"
