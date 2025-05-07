# Java Deployment Pipeline: Quick Start Guide

This guide will help you quickly set up a GitLab CI/CD pipeline for Java applications using systemd services.

![Pipeline Overview](diagrams/pipeline_overview_improved.png)

*Figure 1: Overview of the Java Deployment Pipeline stages*

## Basic Setup (5 minutes)

1. **Copy the Files**: Copy the `.gitlab-ci.yml` and `ci/` directory to your Java project root.

2. **Update Essential Variables**: Edit `ci/variables.yml` and update these key variables:
   ```yaml
   variables:
     # Application name (used for deployment directories and service names)
     APP_NAME: "your-java-app"
     
     # Deployment server hostname or IP address
     DEPLOY_HOST: "your-server.example.com"
     
     # User account on deployment servers
     APP_USER: "your-app-user"
     
     # Email for notifications
     NOTIFICATION_EMAIL: "your-team@example.com"
   ```

3. **Commit and Push**: Commit these changes and push to your GitLab repository.

4. **Run the Pipeline**: Go to CI/CD > Pipelines in GitLab and run your first pipeline.

That's it! Your Java application will be built and deployed using the pipeline.

## Common Java Customizations

### Maven Repository Configuration

The internal Maven Wrapper is configured to use a local repository within the project:

```yaml
variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"
```

### Maven Wrapper Build Options

The pipeline uses an internal Maven Wrapper component for consistent builds. Make sure the Maven Wrapper script has the correct permissions in your repository:

```bash
git update-index --chmod=+x mvnw
```

Default (skip tests):
```yaml
BUILD_COMMAND: "$CI_PROJECT_DIR/mvnw package -DskipTests"
```

With tests:
```yaml
BUILD_COMMAND: "$CI_PROJECT_DIR/mvnw package"
```

With specific profile:
```yaml
BUILD_COMMAND: "$CI_PROJECT_DIR/mvnw package -P production -DskipTests"
```

### Java Runtime Options

Default:
```yaml
RUNTIME_OPTS: "-Xmx512m -Xms256m"
```

For larger applications:
```yaml
RUNTIME_OPTS: "-Xmx2g -Xms1g -XX:+UseG1GC"
```

With system properties:
```yaml
RUNTIME_OPTS: "-Xmx512m -Dspring.profiles.active=${CI_ENVIRONMENT_NAME} -Dserver.port=8080"
```

### JDK Version

```yaml
# In .gitlab-ci.yml, update the build job:
build:
  extends: .build_template
  image: $BUILDER_IMAGE_JAVA_21  # Reference your internal builder image
```

## Testing Without Deploying

To test your pipeline without making actual changes:

```yaml
variables:
  CI_TEST_MODE: "true"
```

## Multiple Environments

The pipeline already supports test, staging, and production environments. Just update the server details in `ci/variables.yml`:

![Environment Workflow](diagrams/environment_workflow_improved.png)

*Figure 2: Environment promotion workflow across branches*

```yaml
# TEST ENVIRONMENT
.test_env_variables:
  variables:
    DEPLOY_HOST: "test-server.example.com"

# STAGING ENVIRONMENT
.staging_env_variables:
  variables:
    DEPLOY_HOST: "staging-server.example.com"

# PRODUCTION ENVIRONMENT
.production_env_variables:
  variables:
    DEPLOY_HOST: "production-server.example.com"
```

## Java-Specific Features

### Health Check URL

For Spring Boot applications:
```yaml
HEALTH_CHECK_URL: "http://localhost:8080/actuator/health"
```

For Quarkus applications:
```yaml
HEALTH_CHECK_URL: "http://localhost:8080/q/health"
```

For custom health endpoints:
```yaml
HEALTH_CHECK_URL: "http://localhost:8080/api/health"
```

### JVM Options for Different Environments

```yaml
# TEST ENVIRONMENT
.test_env_variables:
  variables:
    RUNTIME_OPTS: "-Xmx512m -Dspring.profiles.active=test"

# PRODUCTION ENVIRONMENT
.production_env_variables:
  variables:
    RUNTIME_OPTS: "-Xmx2g -Xms1g -XX:+UseG1GC -Dspring.profiles.active=production"
```

## Testing Your Pipeline

![Rollback Strategy](diagrams/Rollback%20Strategy.png)

*Figure 3: Comprehensive testing of rollback functionality*

We provide several testing approaches with increasing levels of coverage:

### 1. Basic Pipeline Testing

Test the structure and job dependencies without executing actual deployments:

```bash
./tests/test_pipeline.sh
```

### 2. Systemd Service Testing

Validate the systemd service integration in a controlled environment:

```bash
./tests/test_systemd_rollback.sh
```

### 3. Comprehensive Pipeline Testing

Test all aspects of the pipeline including multi-server deployments and rollback:

```bash
./tests/comprehensive_pipeline_test.sh
```

Our testing philosophy is built on a core principle:

> "The files we want to ship are the files under test, with no divergence from that end state."

This means all tests use the exact same files that will be used in production.

## Next Steps

When you're ready to explore more advanced features, check out the full README.md for:
- Multi-server deployments
- Advanced notification options
- Custom health checks
- Rollback strategies
- Comprehensive testing approaches
- And more...
