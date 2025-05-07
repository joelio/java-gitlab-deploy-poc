FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    openjdk-17-jre-headless \
    systemd \
    git \
    bash \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Create directory structure
RUN mkdir -p ci tests/mock-env/{deployments,backups,app,tmp,.config/systemd/user} target

# Copy CI files
COPY ci/ /app/ci/
COPY tests/mock-* /app/tests/
COPY tests/.gitlab-ci.test.yml /app/.gitlab-ci.yml

# Set up environment variables
ENV GITLAB_CI=true \
    CI=true \
    CI_COMMIT_REF_NAME=develop \
    CI_ENVIRONMENT_NAME=test \
    CI_JOB_ID=12345 \
    CI_PROJECT_DIR=/app \
    CI_TEST_MODE=true \
    APP_NAME=test-app \
    APP_VERSION=1.0.0 \
    DEPLOY_HOST=localhost \
    APP_USER=root \
    BASE_PATH=/app/tests/mock-env \
    DEPLOY_DIR=/app/tests/mock-env/deployments \
    BACKUP_DIR=/app/tests/mock-env/backups \
    CURRENT_LINK=/app/tests/mock-env/app/current \
    CONFIG_DIR=/app/tests/mock-env/.config/systemd/user \
    TMP_DIR=/app/tests/mock-env/tmp \
    ARTIFACT_PATTERN=target/*.jar \
    ARTIFACT_PATH=target/test-app-1.0.0.jar \
    ARTIFACT_NAME=test-app-1.0.0.jar \
    NOTIFICATION_METHOD=notification_service \
    NOTIFICATION_SERVICE_URL=/app/tests/mock-notification-service \
    NOTIFICATION_EMAIL=test@example.com

# Create test script
COPY tests/docker/run-tests.sh /app/run-tests.sh
RUN chmod +x /app/run-tests.sh

# Default command
CMD ["/app/run-tests.sh"]
