#!/bin/bash
# Script to build and run Docker container for GitLab CI pipeline testing

set -e

# Terminal colors
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"
CYAN="\033[36m"

# Print a header
print_header() {
    echo -e "${BOLD}${BLUE}===== $1 =====${RESET}"
}

# Print a success message
print_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

# Print an info message
print_info() {
    echo -e "${CYAN}ℹ️ $1${RESET}"
}

# Print an error message
print_error() {
    echo -e "${RED}❌ $1${RESET}"
    exit 1
}

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
fi

# Check Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker first."
fi

print_header "GITLAB CI DOCKER TEST ENVIRONMENT"
print_info "This script will build and run a Docker container to test the GitLab CI pipeline"
print_info "The container will create actual artifacts and verify rollbacks"

# Build the Docker image
print_header "BUILDING DOCKER IMAGE"
print_info "Building gitlab-ci-test image..."

docker build -t gitlab-ci-test -f tests/docker/Dockerfile .
print_success "Docker image built successfully"

# Run the Docker container
print_header "RUNNING DOCKER CONTAINER"
print_info "Running tests in container..."

docker run --rm -it gitlab-ci-test

print_header "DOCKER TESTS COMPLETED"
print_info "The Docker container has completed the tests"
print_info "You can run the tests again with: docker run --rm -it gitlab-ci-test"
print_info "To run with a shell for debugging: docker run --rm -it gitlab-ci-test bash"
