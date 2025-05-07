# Local Testing Guide for GitLab CI/CD Pipeline

This guide provides methods to test the GitLab CI/CD pipeline locally on a Mac M2, targeting Red Hat 8/9 UBI environments with systemd support.

## Testing Approaches

We'll use a combination of tools to test different aspects of the pipeline:

1. **GitLab Runner** - For testing the pipeline syntax and job execution
2. **Podman with systemd** - For testing systemd service deployment
3. **Shell script tests** - For unit testing individual functions

## Prerequisites

Install the required tools on your Mac M2:

```bash
# Install GitLab Runner
brew install gitlab-runner

# Install Podman (for container-based testing)
brew install podman

# Initialize Podman machine with more resources
podman machine init --cpus 2 --memory 4096 --disk-size 20
podman machine start
```

## Testing Pipeline Syntax

Use GitLab CI Lint to validate your pipeline syntax:

```bash
# Create a simple validation script
cat > validate-pipeline.sh << 'EOF'
#!/bin/bash
set -e

echo "Validating GitLab CI/CD pipeline syntax..."
gitlab-runner exec lint .gitlab-ci.yml

if [ $? -eq 0 ]; then
  echo "✅ Pipeline syntax is valid"
else
  echo "❌ Pipeline syntax validation failed"
  exit 1
fi
EOF

chmod +x validate-pipeline.sh
./validate-pipeline.sh
```

## Testing Individual Jobs

Test specific jobs using GitLab Runner in shell executor mode:

```bash
# Example: Test the build job
gitlab-runner exec shell build

# Example: Test the validate_branch job
gitlab-runner exec shell validate_branch
```

## Testing Systemd Services with Podman

Create a Podman container with systemd support to test deployment functions:

```bash
# Create a Dockerfile for RHEL 8 UBI with systemd
cat > Dockerfile.rhel8-systemd << 'EOF'
FROM registry.access.redhat.com/ubi8/ubi:latest

# Install required packages
RUN dnf -y install systemd procps-ng openssh-server openssh-clients java-17-openjdk-devel && dnf clean all

# Configure systemd
RUN systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount \
    && systemctl enable sshd

# Create test user for deployment
RUN useradd -m testuser && \
    mkdir -p /home/testuser/.config/systemd/user && \
    chown -R testuser:testuser /home/testuser/.config

# Setup SSH for testing
RUN mkdir -p /run/sshd && \
    ssh-keygen -A && \
    echo "testuser:password" | chpasswd

# Enable user lingering for systemd user services
RUN loginctl enable-linger testuser

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
EOF

# Build the container image
podman build -t rhel8-systemd -f Dockerfile.rhel8-systemd

# Run the container with systemd support
podman run --name rhel8-test -d --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro rhel8-systemd

# Test SSH connection to the container
podman exec -it rhel8-test ssh testuser@localhost
```

## Testing Deployment Functions

Create a test script to verify the deployment functions:

```bash
# Create a test script for deployment functions
cat > test-deployment-functions.sh << 'EOF'
#!/bin/bash
set -e

CONTAINER_NAME="rhel8-test"
TEST_USER="testuser"

echo "Testing deployment functions in container $CONTAINER_NAME..."

# Copy the functions.yml to the container
podman cp ci/functions.yml $CONTAINER_NAME:/tmp/functions.yml

# Create a test script to source and test functions
cat > test-functions.sh << 'EOFF'
#!/bin/bash
source /tmp/functions.yml

# Set test variables
APP_NAME="test-app"
APP_USER="testuser"
DEPLOY_HOST="localhost"
BASE_PATH="/home/testuser"
DEPLOY_DIR="${BASE_PATH}/deployments"
BACKUP_DIR="${BASE_PATH}/backups"
CURRENT_LINK="${BASE_PATH}/app/current"
TMP_DIR="${BASE_PATH}/tmp"
CONFIG_DIR="${BASE_PATH}/.config/systemd/user"
CI_TEST_MODE="true"

# Test create_directories function
echo "Testing create_directories function..."
create_directories
if [ -d "$DEPLOY_DIR" ] && [ -d "$BACKUP_DIR" ]; then
  echo "✅ create_directories passed"
else
  echo "❌ create_directories failed"
  exit 1
fi

# Test backup_current_deployment function
echo "Testing backup_current_deployment function..."
backup_current_deployment
echo "✅ backup_current_deployment passed (in test mode)"

# Test create_deployment_dir function
echo "Testing create_deployment_dir function..."
DEPLOY_DIR_RESULT=$(create_deployment_dir)
if [ -n "$DEPLOY_DIR_RESULT" ]; then
  echo "✅ create_deployment_dir passed: $DEPLOY_DIR_RESULT"
else
  echo "❌ create_deployment_dir failed"
  exit 1
fi

# Test setup_systemd_service function
echo "Testing setup_systemd_service function..."
setup_systemd_service
echo "✅ setup_systemd_service passed (in test mode)"

echo "All deployment function tests passed!"
EOFF

# Copy the test script to the container
podman cp test-functions.sh $CONTAINER_NAME:/home/$TEST_USER/test-functions.sh

# Make the script executable and run it
podman exec -it $CONTAINER_NAME bash -c "chmod +x /home/$TEST_USER/test-functions.sh && su - $TEST_USER -c '/home/$TEST_USER/test-functions.sh'"

# Clean up
rm test-functions.sh
echo "Deployment function tests completed."
EOF

chmod +x test-deployment-functions.sh
```

## Testing the Full Pipeline

Create a test script that simulates the entire pipeline execution:

```bash
# Create a full pipeline test script
cat > test-full-pipeline.sh << 'EOF'
#!/bin/bash
set -e

echo "Testing full GitLab CI/CD pipeline..."

# Set test variables
export CI_COMMIT_REF_NAME="develop"
export CI_ENVIRONMENT_NAME="test"
export CI_JOB_ID="12345"
export CI_TEST_MODE="true"

# Run each stage in sequence
echo "Stage: validate"
gitlab-runner exec shell validate_branch

echo "Stage: build"
gitlab-runner exec shell build

echo "Stage: deploy"
gitlab-runner exec shell deploy_test

echo "Stage: notify"
gitlab-runner exec shell notify_success_test

echo "Testing rollback..."
gitlab-runner exec shell rollback_manual_test

echo "✅ Full pipeline test completed successfully"
EOF

chmod +x test-full-pipeline.sh
```

## Integration with Sample Java Application

Create a simple Java application to test the full deployment process:

```bash
# Create a sample Java application directory
mkdir -p test-app/src/main/java/com/example
mkdir -p test-app/src/main/resources

# Create a simple Spring Boot application
cat > test-app/src/main/java/com/example/Application.java << 'EOF'
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @GetMapping("/")
    public String home() {
        return "Hello from the test application!";
    }
    
    @GetMapping("/healthcheck")
    public String health() {
        return "OK";
    }
}
EOF

# Create a simple POM file
cat > test-app/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.0</version>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>test-app</artifactId>
    <version>1.0.0</version>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Create Maven wrapper
cd test-app
mvn wrapper:wrapper
chmod +x mvnw
cd ..
```

## Running the Tests

Execute the tests in sequence:

```bash
# 1. Validate pipeline syntax
./validate-pipeline.sh

# 2. Test individual functions
./test-deployment-functions.sh

# 3. Test the full pipeline
./test-full-pipeline.sh
```

## Cleaning Up

Clean up test resources when finished:

```bash
# Stop and remove the test container
podman stop rhel8-test
podman rm rhel8-test

# Remove the container image
podman rmi rhel8-systemd
```

## Troubleshooting

### Common Issues and Solutions

1. **Architecture Compatibility**:
   - If you encounter architecture compatibility issues, use the `--platform=linux/amd64` flag with Podman commands.

2. **Systemd in Containers**:
   - Ensure the container has the necessary privileges with `--privileged` and proper volume mounts.

3. **SSH Connection Issues**:
   - Verify SSH is running in the container: `podman exec rhel8-test systemctl status sshd`

4. **GitLab Runner Errors**:
   - Check GitLab Runner configuration with `gitlab-runner verify`
   - Ensure the `.gitlab-ci.yml` file is valid

5. **Java Version Compatibility**:
   - Ensure the container has the correct Java version installed for your application
