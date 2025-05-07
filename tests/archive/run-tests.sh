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
  source tests/test-functions.sh
  
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
  source tests/test-functions.sh
  
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
  source tests/test-functions.sh
  
  # Test notification
  send_notification 'SUCCESS' 'Test notification'
  
  echo 'Notification test completed'
"

echo "All tests completed successfully! 🎉"
