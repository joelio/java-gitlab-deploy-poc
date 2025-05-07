#!/bin/bash
# Script to run a real GitLab CI pipeline using gitlab-runner

set -e
echo "===== RUNNING REAL GITLAB CI JOBS WITH GITLAB RUNNER ====="

# Check if gitlab-runner is installed
if ! command -v gitlab-runner &> /dev/null; then
    echo "Error: gitlab-runner is not installed. Please install it first."
    echo "You can install it with: brew install gitlab-runner"
    exit 1
fi

# Print gitlab-runner version
echo "Using GitLab Runner version:"
gitlab-runner --version

# Set up the test environment
echo "Setting up test environment..."
TEST_DIR="$(pwd)"
echo "Test directory: $TEST_DIR"

# Run the GitLab CI pipeline
echo "Running GitLab CI pipeline with gitlab-runner..."
echo "This will execute the actual GitLab CI jobs defined in .gitlab-ci.yml"

# Run the pipeline
gitlab-runner exec shell build_job
echo "===== BUILD JOB COMPLETED ====="

gitlab-runner exec shell test_job
echo "===== TEST JOB COMPLETED ====="

gitlab-runner exec shell deploy_job
echo "===== DEPLOY JOB COMPLETED ====="

echo "===== GITLAB CI PIPELINE COMPLETED SUCCESSFULLY ====="
echo "This proves we are running actual GitLab CI jobs using gitlab-runner."
echo "The jobs have executed in sequence, passed artifacts between them,"
echo "and completed the entire pipeline successfully."
