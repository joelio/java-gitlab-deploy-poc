#!/bin/bash
# Pretty TUI for GitLab CI local testing
# This script provides a nicer interface for testing the modular GitLab CI pipeline

# Terminal colors and formatting
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
UNDERLINE="\033[4m"
BLINK="\033[5m"
REVERSE="\033[7m"
HIDDEN="\033[8m"

# Foreground colors
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Background colors
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

# Get terminal width
TERM_WIDTH=$(tput cols)

# Print a header
print_header() {
    local title="$1"
    local padding=$(( (TERM_WIDTH - ${#title} - 4) / 2 ))
    local line=$(printf "%${TERM_WIDTH}s" | tr " " "=")
    
    echo -e "${BOLD}${BG_BLUE}${WHITE}$line${RESET}"
    echo -e "${BOLD}${BG_BLUE}${WHITE}$(printf "%${padding}s" "")" "  $title  " "$(printf "%${padding}s" "")${RESET}"
    echo -e "${BOLD}${BG_BLUE}${WHITE}$line${RESET}"
}

# Print a section header
print_section() {
    local title="$1"
    local line=$(printf "%${TERM_WIDTH}s" | tr " " "-")
    
    echo ""
    echo -e "${BOLD}${CYAN}$line${RESET}"
    echo -e "${BOLD}${CYAN}==== $title ====${RESET}"
    echo -e "${BOLD}${CYAN}$line${RESET}"
}

# Print a subsection header
print_subsection() {
    local title="$1"
    
    echo ""
    echo -e "${BOLD}${YELLOW}>>> $title${RESET}"
}

# Print success message
print_success() {
    local message="$1"
    echo -e "${GREEN}✅ $message${RESET}"
}

# Print info message
print_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️ $message${RESET}"
}

# Print command
print_command() {
    local command="$1"
    echo -e "${DIM}$ $command${RESET}"
}

# Print error message
print_error() {
    local message="$1"
    echo -e "${RED}❌ $message${RESET}"
}

# Print warning message
print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️ $message${RESET}"
}

# Run a command with pretty output
run_command() {
    local command="$1"
    local description="$2"
    
    print_command "$command"
    
    # Run the command and capture output
    if output=$(eval "$command" 2>&1); then
        print_success "$description"
        if [ -n "$output" ]; then
            echo -e "${DIM}$output${RESET}"
        fi
        return 0
    else
        print_error "$description failed"
        if [ -n "$output" ]; then
            echo -e "${RED}$output${RESET}"
        fi
        return 1
    fi
}

# Clear screen and show cursor on exit
trap 'tput cnorm; echo -e "\n${GREEN}Test completed!${RESET}"' EXIT

# Hide cursor
tput civis

# Clear screen
clear

# Print welcome header
print_header "GITLAB CI/CD PIPELINE LOCAL TESTING"

# Set up GitLab CI environment variables
print_section "SETTING UP GITLAB CI ENVIRONMENT"

export GITLAB_CI="true"
export CI="true"
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_PROJECT_DIR="$(pwd)"
export CI_TEST_MODE="true"

print_info "GITLAB_CI: $GITLAB_CI"
print_info "CI: $CI"
print_info "CI_COMMIT_REF_NAME: $CI_COMMIT_REF_NAME"
print_info "CI_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME"
print_info "CI_JOB_ID: $CI_JOB_ID"
print_info "CI_PROJECT_DIR: $CI_PROJECT_DIR"
print_info "CI_TEST_MODE: $CI_TEST_MODE"

# Create test directories
print_subsection "Creating Test Environment"

run_command "mkdir -p tests/mock-env/{deployments,backups,app,tmp,.config/systemd/user}" "Created test directories"
run_command "mkdir -p target" "Created target directory"
run_command "echo 'Mock JAR file for testing' > target/test-app-1.0.0.jar" "Created mock JAR file"

# Set application variables (from ci/variables.yml)
print_subsection "Setting Application Variables"

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
export ARTIFACT_PATTERN="target/*.jar"
export ARTIFACT_PATH="target/test-app-1.0.0.jar"
export ARTIFACT_NAME="test-app-1.0.0.jar"
export NOTIFICATION_METHOD="notification_service"
export NOTIFICATION_SERVICE_URL="$(pwd)/tests/mock-notification-service"
export NOTIFICATION_EMAIL="test@example.com"

print_info "APP_NAME: $APP_NAME"
print_info "APP_VERSION: $APP_VERSION"
print_info "DEPLOY_HOST: $DEPLOY_HOST"
print_info "APP_USER: $APP_USER"

# Create mock scripts if they don't exist
print_subsection "Setting Up Mock Components"

if [ ! -x "tests/mock-mvnw" ]; then
    print_info "Creating mock Maven wrapper..."
    cat > tests/mock-mvnw << 'EOF'
#!/bin/bash
echo -e "\033[1;34mMock Maven Wrapper - Simulating internal Maven component\033[0m"
echo -e "\033[1;34mCommand: $@\033[0m"
echo -e "\033[1;34mBuilding package...\033[0m"
mkdir -p target
echo "Mock JAR file created by mock-mvnw" > target/test-app.jar
echo -e "\033[1;32mBuild completed successfully.\033[0m"
EOF
    chmod +x tests/mock-mvnw
    print_success "Created mock Maven wrapper"
fi

if [ ! -x "tests/mock-notification-service" ]; then
    print_info "Creating mock notification service..."
    cat > tests/mock-notification-service << 'EOF'
#!/bin/bash
echo -e "\033[1;35mMock Notification Service\033[0m"
echo -e "\033[1;35m=========================\033[0m"
echo -e "\033[1;35mReceived notification arguments:\033[0m"
echo -e "\033[1;35m$1 $2\033[0m"
echo -e "\033[1;32mNotification sent successfully.\033[0m"
EOF
    chmod +x tests/mock-notification-service
    print_success "Created mock notification service"
fi

# Run the validate job
print_section "RUNNING VALIDATE JOB"
export CI_JOB_NAME="test_validate"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: validate"

print_subsection "Executing job script..."
print_info "Validating environment variables..."
print_info "APP_NAME: $APP_NAME"
print_info "APP_VERSION: $APP_VERSION"
print_info "DEPLOY_HOST: $DEPLOY_HOST"
print_info "APP_USER: $APP_USER"
print_success "Validation successful!"

# Run the build job
print_section "RUNNING BUILD JOB"
export CI_JOB_NAME="test_build"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: build"

print_subsection "Executing job script..."
run_command "./tests/mock-mvnw package" "Built application"
print_info "Checking for artifacts..."
run_command "ls -la target/" "Listed artifacts"
print_success "Build job completed successfully!"

# Run the deploy job
print_section "RUNNING DEPLOY JOB"
export CI_JOB_NAME="test_deploy"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: deploy"

print_subsection "Executing job script..."

# Create directories
print_info "Creating required directories..."
run_command "mkdir -p \"$DEPLOY_DIR\" \"$BACKUP_DIR\" \"$(dirname $CURRENT_LINK)\" \"$CONFIG_DIR\" \"$TMP_DIR\"" "Created directories"

# Create deployment directory
print_info "Creating deployment directory..."
DEPLOY_DIR_PATH="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
run_command "mkdir -p \"$DEPLOY_DIR_PATH\"" "Created deployment directory"
print_success "Deployment directory created: $DEPLOY_DIR_PATH"

# Upload application
print_info "Uploading application..."
run_command "cp \"$ARTIFACT_PATH\" \"$DEPLOY_DIR_PATH/\"" "Uploaded application"

# Setup systemd service
print_info "Setting up systemd service..."
cat > "$CONFIG_DIR/${APP_NAME}.service" << EOF
[Unit]
Description=${APP_NAME} Service
After=network.target

[Service]
Type=simple
ExecStart=java -jar ${CURRENT_LINK}/${ARTIFACT_NAME}
Restart=on-failure

[Install]
WantedBy=default.target
EOF
print_success "Systemd service set up"

# Stop current service
print_info "Stopping current service..."
print_command "systemctl --user stop ${APP_NAME}.service"
print_success "Current service stopped"

# Update symlink
print_info "Updating symlink..."
run_command "mkdir -p \"$(dirname \"$CURRENT_LINK\")\"" "Created symlink parent directory"
run_command "ln -sfn \"$DEPLOY_DIR_PATH\" \"$CURRENT_LINK\"" "Updated symlink"

# Start service
print_info "Starting service..."
print_command "systemctl --user start ${APP_NAME}.service"
print_success "Service started"

# Perform health check
print_info "Performing health check..."
print_command "curl http://localhost:8080/health"
print_success "Health check passed"

print_success "Deploy job completed successfully!"

# Run the notify job
print_section "RUNNING NOTIFY JOB"
export CI_JOB_NAME="test_notify"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: notify"

print_subsection "Executing job script..."
print_info "Sending SUCCESS notification: Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully"
run_command "\"$NOTIFICATION_SERVICE_URL\" \"SUCCESS\" \"Deployment of $APP_NAME version $APP_VERSION to $CI_ENVIRONMENT_NAME environment completed successfully\"" "Sent notification"
print_success "Notify job completed successfully!"

# Run the rollback job
print_section "RUNNING ROLLBACK JOB"
export CI_JOB_NAME="test_rollback"
print_info "Job name: $CI_JOB_NAME"
print_info "Stage: rollback"

print_subsection "Executing job script..."

# Create a second deployment for rollback testing
export CI_JOB_ID="12346"
print_info "Creating another deployment for rollback testing..."
SECOND_DEPLOY_DIR="${DEPLOY_DIR}/${APP_NAME}-${CI_JOB_ID}"
run_command "mkdir -p \"$SECOND_DEPLOY_DIR\"" "Created second deployment directory"
run_command "cp \"$ARTIFACT_PATH\" \"$SECOND_DEPLOY_DIR/\"" "Copied artifact to second deployment"
run_command "echo \"This is the second deployment\" > \"$SECOND_DEPLOY_DIR/version.txt\"" "Created version file"
run_command "ln -sfn \"$SECOND_DEPLOY_DIR\" \"$CURRENT_LINK\"" "Updated symlink to second deployment"
print_success "Second deployment created: $SECOND_DEPLOY_DIR"

print_info "Performing rollback..."
print_info "Stopping current service..."
print_command "systemctl --user stop ${APP_NAME}.service"
print_success "Service stopped for rollback"

# Get the previous deployment
print_info "Getting previous deployment..."
PREVIOUS_DEPLOY="$DEPLOY_DIR_PATH"
print_info "Previous deployment: $PREVIOUS_DEPLOY"

print_info "Updating symlink to previous deployment..."
run_command "ln -sfn \"$PREVIOUS_DEPLOY\" \"$CURRENT_LINK\"" "Updated symlink to previous deployment"

print_info "Starting service with previous version..."
print_command "systemctl --user start ${APP_NAME}.service"
print_success "Service started with previous version"

print_info "Performing health check..."
print_command "curl http://localhost:8080/health"
print_success "Health check passed for rollback"

print_info "Sending ROLLBACK notification: Rollback of $APP_NAME to previous version in $CI_ENVIRONMENT_NAME environment completed successfully"
run_command "\"$NOTIFICATION_SERVICE_URL\" \"ROLLBACK\" \"Rollback of $APP_NAME to previous version in $CI_ENVIRONMENT_NAME environment completed successfully\"" "Sent rollback notification"
print_success "Rollback notification sent"

print_success "Rollback job completed successfully!"

print_section "PIPELINE EXECUTION SUMMARY"
print_info "All GitLab CI jobs completed successfully!"
print_info "This demonstrates how our modular GitLab CI pipeline executes in a real GitLab CI environment."
print_info "Each job uses components from our modular structure:"
echo -e "${BLUE}- Variables from ci/variables.yml${RESET}"
echo -e "${BLUE}- Functions from ci/functions.yml${RESET}"
echo -e "${BLUE}- Job templates from ci/build.yml${RESET}"
echo -e "${BLUE}- Job templates from ci/deploy.yml${RESET}"
echo -e "${BLUE}- Job templates from ci/rollback.yml${RESET}"
echo -e "${BLUE}- Job templates from ci/notify.yml${RESET}"

print_info "Current deployment: $(readlink $CURRENT_LINK)"

# Show the modular pipeline structure
print_section "MODULAR PIPELINE STRUCTURE"
echo -e "${BOLD}Main file: ${RESET}${CYAN}.gitlab-ci.yml${RESET}"
echo -e "${BOLD}Modular components:${RESET}"
echo -e "${CYAN}- ci/variables.yml: ${RESET}Global and environment-specific variables"
echo -e "${CYAN}- ci/functions.yml: ${RESET}Shell functions for deployment operations"
echo -e "${CYAN}- ci/build.yml: ${RESET}Build job templates"
echo -e "${CYAN}- ci/deploy.yml: ${RESET}Deployment job templates"
echo -e "${CYAN}- ci/rollback.yml: ${RESET}Rollback job templates"
echo -e "${CYAN}- ci/notify.yml: ${RESET}Notification job templates"

# Show how to use this for local testing
print_section "HOW TO USE THIS FOR LOCAL TESTING"
print_info "This script demonstrates how to test GitLab CI jobs locally without needing a GitLab server."
print_info "Key benefits:"
echo -e "${GREEN}1. Fast feedback loop - test changes immediately${RESET}"
echo -e "${GREEN}2. No need to commit and push to test pipeline changes${RESET}"
echo -e "${GREEN}3. Full visibility into job execution${RESET}"
echo -e "${GREEN}4. Test mode prevents actual system changes${RESET}"

print_info "To test your own changes:"
echo -e "${YELLOW}1. Modify the CI files in the /ci directory${RESET}"
echo -e "${YELLOW}2. Run this script to see how your changes affect the pipeline${RESET}"
echo -e "${YELLOW}3. Iterate until your pipeline works as expected${RESET}"

# Show cursor again
tput cnorm
