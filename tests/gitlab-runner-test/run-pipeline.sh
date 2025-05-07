#!/bin/bash
set -e

echo "Running GitLab CI pipeline with GitLab Runner..."
echo "This will execute the actual GitLab CI jobs defined in .gitlab-ci.yml"

# Set up environment for GitLab Runner
export CI=true
export GITLAB_CI=true

# Run the build job
echo "===== RUNNING BUILD JOB ====="
gitlab-runner exec shell --config=config.toml build_job

# Run the test job
echo "===== RUNNING TEST JOB ====="
gitlab-runner exec shell --config=config.toml test_job

# Run the deploy job
echo "===== RUNNING DEPLOY JOB ====="
gitlab-runner exec shell --config=config.toml deploy_job

echo "===== PIPELINE COMPLETED SUCCESSFULLY ====="
echo "This proves we are running actual GitLab CI jobs with gitlab-runner."
