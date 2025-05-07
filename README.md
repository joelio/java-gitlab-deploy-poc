# Java Application Deployment Pipeline

A modular, multi-environment GitLab CI/CD pipeline for Java application deployment with automated rollback capabilities.

## Overview

This repository contains a GitLab CI/CD configuration for deploying a Java application to multiple environments (test, staging, production) with comprehensive deployment, rollback, and notification capabilities. The pipeline is designed to be modular, maintainable, and follows GitLab CI/CD best practices.

## Pipeline Structure

The CI/CD pipeline is organized into the following stages:

1. **Validate**: Ensures deployments only occur from protected branches
2. **Build**: Compiles and packages the Java application
3. **Deploy**: Deploys the application to the target environment
4. **Notify**: Sends notifications about deployment success/failure
5. **Rollback**: Handles automatic and manual rollbacks if needed

## Directory Structure

```
.
├── .gitlab-ci.yml           # Main CI/CD configuration file
└── ci/                      # Modular CI components
    ├── variables.yml        # Global and environment-specific variables
    ├── functions.yml        # Reusable shell functions
    ├── build.yml            # Build job templates
    ├── deploy.yml           # Deployment job templates
    ├── rollback.yml         # Rollback job templates
    └── notify.yml           # Notification job templates
```

## Environment Support

The pipeline supports three environments with multi-server deployment capabilities:

1. **Test**
   - Single server deployment: `test-server.example.com`
   - Manual deployments from `develop` branch and feature branches
   - Customised for testing purposes
   - Auto-promotion prevention enabled

2. **Staging**
   - Multi-server deployment: `staging-server-1.example.com`, `staging-server-2.example.com`
   - Manual deployments from `develop` or `release/*` branches
   - Uses `staging-appuser` for deployment
   - Auto-promotion prevention enabled

3. **Production**
   - Multi-server deployment: `production-server-1.example.com`, `production-server-2.example.com`
   - Manual deployments from `main`, `master`, or `production` branches
   - Uses `prod-appuser` for deployment
   - Notification Service enabled
   - Auto-promotion prevention enabled

## Features

- **Modular Design**: Pipeline components are separated into reusable, maintainable files
- **Multi-Runtime Support**: Deploy Java, .NET, Node.js, and other application types
- **Multi-Environment Support**: Configured for test, staging, and production environments
- **Multi-Server Deployment**: Deploy to multiple servers within an environment
- **Auto-Promotion Prevention**: Ensure deployments are manually triggered between environments
- **Robust Error Handling**: Comprehensive logging and error recovery
- **Test Mode**: Simulate pipeline execution without making actual changes
- **Automated Rollback**: Recover from failed deployments automatically
- **Manual Rollbacks**: On-demand rollback capability for each environment
- **Deployment Retention**: Configurable number of deployments to retain
- **Health Checks**: Validates deployment success with configurable retries
- **Notifications**: Flexible notification system supporting email and Notification Service
- **Test Mode**: Ability to simulate deployments without making actual changes
- **Detailed Logging**: Comprehensive logging with timestamps and log levels

## SSH Authentication

The pipeline uses `sshpass` for SSH authentication. All SSH commands are wrapped in functions that handle authentication consistently:

```bash
function ssh_cmd() {
  sshpass $sshpass ssh ${APP_USER}@$DEPLOY_HOST "$@"
}
```

## Multi-Runtime Support

The pipeline now supports any application type through a generic, configurable approach:

- **Runtime Agnostic**: Deploy any type of application by configuring a few key variables
- **Flexible Configuration**: Customise build commands, runtime paths, and service configuration
- **Artifact Handling**: Smart detection of single files vs. directories for proper packaging
- **Systemd Service Templates**: Fully configurable service files with custom commands and environment variables

### Example Configuration

```yaml
variables:
  # Application details
  APP_NAME: "my-application"
  APP_VERSION: "1.0.0"
  
  # Build configuration
  BUILD_COMMAND: "mvn clean package -DskipTests"  # Or any other build command
  
  # Artifact settings
  ARTIFACT_PATTERN: "target/*.jar"  # Pattern to locate artifacts
  ARTIFACT_PATH: "target/my-app.jar"  # Specific artifact path
  ARTIFACT_NAME: "my-app.jar"  # Name when deployed
  
  # Runtime configuration
  RUNTIME_PATH: "/usr/bin/java"  # Path to runtime executable
  RUNTIME_OPTS: "-Xmx512m"  # Runtime options
  
  # Service configuration
  START_COMMAND: "/usr/bin/java -Xmx512m -jar /opt/app/current/my-app.jar"
  WORKING_DIRECTORY: "/opt/app"
  SERVICE_ENV_VARS: "BUILD_ID=${CI_JOB_ID},ENV=${CI_ENVIRONMENT_NAME}"
```

### For Java Applications

```yaml
BUILD_COMMAND: "mvn clean package -DskipTests"
ARTIFACT_PATTERN: "target/*.jar"
START_COMMAND: "${RUNTIME_PATH} ${RUNTIME_OPTS} -jar ${CURRENT_LINK}/${ARTIFACT_NAME}"
```

### For .NET Applications

```yaml
BUILD_COMMAND: "dotnet publish -c Release"
ARTIFACT_PATTERN: "bin/Release/net6.0/publish/*"
START_COMMAND: "${RUNTIME_PATH} ${CURRENT_LINK}/${APP_NAME}.dll ${RUNTIME_OPTS}"
```

### For Node.js Applications

```yaml
BUILD_COMMAND: "npm ci && npm run build"
ARTIFACT_PATTERN: "dist/*"
START_COMMAND: "${RUNTIME_PATH} ${CURRENT_LINK}/index.js"
```

### Deployment Process

The deployment process is now runtime-agnostic:

1. **Build**: Executes the configured `BUILD_COMMAND`
2. **Artifact Collection**: Collects artifacts using the specified pattern or path
3. **Upload**: Automatically handles single files or directories appropriately
4. **Service Configuration**: Creates systemd service using the configured start command and environment variables

## Multi-Server Deployment

The pipeline supports deploying to multiple servers within a single environment:

- **Configuration**: Set `MULTI_SERVER_DEPLOYMENT: "true"` and define servers in the `DEPLOY_HOSTS` array
- **Sequential Deployment**: Servers are deployed to one after another
- **Validation**: Each server must pass health checks before proceeding to the next
- **Fallback**: If multi-server mode is disabled, falls back to single server (`DEPLOY_HOST`)
- **Error Handling**: If deployment fails on any server, the entire job fails
- **Testing**: Comprehensive testing validates multi-server deployment and rollback

### Example Configuration

```yaml
variables:
  MULTI_SERVER_DEPLOYMENT: "true"
  DEPLOY_HOSTS: '["server1.example.com", "server2.example.com"]'
  DEPLOY_HOST: "server1.example.com"  # Fallback for single-server mode
```

## Auto-Promotion Prevention

To ensure controlled deployments and comply with the May 2025 GitLab protected branch updates:

- **Manual Approval**: All environment promotions require manual approval
- **Configuration**: Set `AUTO_PROMOTION: "false"` in environment variables
- **Branch Protection**: Works with GitLab's protected branch rules
- **Safety Check**: Pipeline validates that deployments are manually triggered
- **Compliance**: Helps maintain compliance with TADS CO-014-04 standards

### Example Configuration

```yaml
variables:
  AUTO_PROMOTION: "false"  # Prevents automatic promotion between environments
```

## Deployment Process

1. Validate branch permissions and auto-promotion settings
2. Build the application
3. Create deployment directories
4. Backup current deployment
5. Upload application JAR
6. Configure systemd service
7. Update symlinks for atomic deployment
8. Start the service
9. Perform health checks
10. Clean up old deployments
11. Send notifications

## Testing

The pipeline includes a comprehensive testing framework to ensure it works correctly in all environments:

- **Principle**: "The files we want to ship are the files under test, with no divergence from that end state"
- **Scripts**: Multiple test scripts with increasing levels of coverage (see `/tests` directory)
- **Components**:
  - Basic pipeline structure validation using gitlab-ci-local
  - systemd service testing with rollback functionality
  - Multi-server deployment simulation
  - Edge case handling for service failures
- **Containers**: Tests run in Podman containers with systemd support to simulate real environments
- **Comprehensive Coverage**: All aspects of the pipeline are tested, including deployment, rollback, and service management

See the [tests/README.md](tests/README.md) for detailed information about the testing approach.

## Rollback Mechanism

The pipeline includes two types of rollbacks:

1. **Automatic Rollback**: Triggered on deployment failure
2. **Manual Rollback**: Can be manually triggered for any environment

Rollbacks can use either:
- The last successful deployment ID
- The latest backup if no successful deployment ID exists

## Configuration

### Environment Variables

Key variables that can be customised:

- `APP_NAME`: Name of the Java application
- `APP_USER`: User for deployment operations
- `MAX_BACKUPS`: Number of backups to retain
- `HEALTH_CHECK_URL`: URL to validate deployment
- `HEALTH_CHECK_RETRIES`: Number of health check attempts
- `NOTIFICATION_METHOD`: How to send notifications (email, notification_service)

### Branch Rules

- **Test**: `develop`, `feature/*`
- **Staging**: `develop`, `release/*`
- **Production**: `main`, `master`, `production`

## Usage

### Prerequisites

- GitLab CI/CD runner with shell executor
- SSH access to deployment servers
- Java 17 installed on deployment servers
- Maven for building the application

### Customisation

1. Update server hostnames in `ci/variables.yml`
2. Configure environment-specific variables as needed
3. Adjust branch rules in the deployment jobs if necessary
4. Set up notification preferences

## Best Practices Implemented

- Modular configuration using `include`
- Template inheritance with `extends`
- Environment-specific configurations
- Reusable shell functions
- Atomic deployments
- Health validation
- Automated rollbacks
- Retention policies

## Security Considerations

- Protected variables for sensitive information
- User-specific deployments
- Systemd service isolation
- Branch protection rules

## Troubleshooting

If deployments fail:

1. Check the job logs for specific error messages
2. Verify SSH connectivity to the deployment server
3. Ensure the health check endpoint is properly configured
4. Check systemd service logs on the deployment server

## Licence

[MIT Licence](LICENSE)
