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
