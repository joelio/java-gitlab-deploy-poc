#!/bin/bash
# Script to run GitLab CI pipeline locally using gitlab-ci-local
# This script demonstrates running the modular GitLab CI pipeline with proper GitLab CI simulation

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

# Check if gitlab-ci-local is installed
if ! command -v gitlab-ci-local &> /dev/null; then
    print_error "gitlab-ci-local is not installed. Please install it with: brew install gitlab-ci-local"
fi

print_header "GITLAB CI LOCAL TESTING"
print_info "This script runs the GitLab CI pipeline locally using gitlab-ci-local"
print_info "This provides a more accurate simulation of the actual GitLab CI environment"

# Create mock environment directories
print_info "Creating mock environment directories..."
mkdir -p mock-env/{deployments,backups,app,tmp,.config/systemd/user}
print_success "Mock environment directories created"

# List available jobs
print_header "AVAILABLE JOBS"
gitlab-ci-local --list

# Run the pipeline
print_header "RUNNING PIPELINE"
print_info "Running the complete pipeline..."

# Run with verbose output
gitlab-ci-local --verbose

print_header "PIPELINE EXECUTION COMPLETED"
print_info "The GitLab CI pipeline has been executed locally"
print_info "Check the output above for details on each job's execution"

# Show the current deployment
if [ -L "mock-env/app/current" ]; then
    print_info "Current deployment: $(readlink mock-env/app/current)"
else
    print_info "No current deployment found"
fi

print_header "TESTING SPECIFIC JOBS"
print_info "You can also run specific jobs with:"
echo "gitlab-ci-local test_validate"
echo "gitlab-ci-local test_build"
echo "gitlab-ci-local test_deploy"
echo "gitlab-ci-local test_notify"
echo "gitlab-ci-local test_rollback"

print_header "ADVANCED USAGE"
print_info "For more options, run: gitlab-ci-local --help"
print_info "Some useful options:"
echo "  --verbose                   Show verbose output"
echo "  --variable KEY=VALUE        Set a variable"
echo "  --list                      List all jobs"
echo "  --graph                     Show job dependency graph"
