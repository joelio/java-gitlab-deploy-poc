#!/bin/bash
# Run the pipeline with Docker Compose

set -e
echo "Running GitLab CI pipeline with Docker Compose..."

# Run the pipeline
docker-compose up --build

echo "Pipeline execution completed!"
