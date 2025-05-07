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
