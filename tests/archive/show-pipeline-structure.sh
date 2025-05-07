#!/bin/bash
# Script to show the structure and flow of the modular GitLab CI/CD pipeline
# This script focuses on explaining the pipeline rather than executing it

set -e
echo "===== GITLAB CI/CD PIPELINE STRUCTURE AND FLOW ====="
echo ""

# Show the actual structure of the modular pipeline
echo "===== MODULAR PIPELINE STRUCTURE ====="
echo "Main file: .gitlab-ci.yml"
echo "Modular components:"
echo "- ci/variables.yml: Global and environment-specific variables"
echo "- ci/functions.yml: Shell functions for deployment operations"
echo "- ci/build.yml: Build job templates for Java applications"
echo "- ci/deploy.yml: Deployment job templates for systemd services"
echo "- ci/rollback.yml: Rollback job templates"
echo "- ci/notify.yml: Notification job templates for the Notification Service"
echo ""

# Show how the components are included in the main file
echo "===== MAIN .GITLAB-CI.YML STRUCTURE ====="
cat << 'EOF'
include:
  - local: '/ci/variables.yml'
  - local: '/ci/functions.yml'
  - local: '/ci/build.yml'
  - local: '/ci/deploy.yml'
  - local: '/ci/rollback.yml'
  - local: '/ci/notify.yml'

stages:
  - validate
  - build
  - test
  - deploy
  - notify
  - rollback

# Jobs extend templates from the modular components
build_java:
  extends: .build_java
  stage: build

deploy_to_dev:
  extends: .deploy
  stage: deploy
  environment: dev
EOF
echo ""

# Show the pipeline flow
echo "===== PIPELINE FLOW ====="
echo "1. VALIDATE STAGE"
echo "   - Validate branch names and configurations"
echo "   - Ensure required variables are set"
echo ""
echo "2. BUILD STAGE"
echo "   - Build Java application using the internal Maven component"
echo "   - Run tests"
echo "   - Create build artifacts (JAR files)"
echo ""
echo "3. TEST STAGE"
echo "   - Run additional tests if needed"
echo "   - Code quality checks"
echo ""
echo "4. DEPLOY STAGE"
echo "   - Create deployment directory on target server"
echo "   - Backup current deployment"
echo "   - Upload application artifacts"
echo "   - Setup systemd service"
echo "   - Stop current service"
echo "   - Update symlink to new deployment"
echo "   - Enable linger for user service"
echo "   - Start new service"
echo "   - Perform health checks"
echo ""
echo "5. NOTIFY STAGE"
echo "   - Send notification via the Notification Service"
echo "   - Include deployment details and status"
echo ""
echo "6. ROLLBACK STAGE (Manual or Automatic)"
echo "   - Stop current service"
echo "   - Update symlink to previous deployment"
echo "   - Start service with previous version"
echo "   - Perform health checks"
echo "   - Send rollback notification"
echo ""

# Show the deployment process
echo "===== DEPLOYMENT PROCESS ====="
cat << 'EOF'
1. SSH to target server
2. Create deployment directory: /home/app-user/deployments/app-name-{job-id}
3. Copy JAR file to deployment directory
4. Create systemd service file in user's .config/systemd/user directory
5. Stop current service: systemctl --user stop app-name.service
6. Update symlink: ln -sfn /home/app-user/deployments/app-name-{job-id} /home/app-user/app/current
7. Start service: systemctl --user start app-name.service
8. Check health endpoint: curl http://localhost:8080/health
EOF
echo ""

# Show the rollback process
echo "===== ROLLBACK PROCESS ====="
cat << 'EOF'
1. Identify rollback target (previous successful deployment)
2. SSH to target server
3. Stop current service: systemctl --user stop app-name.service
4. Update symlink to previous deployment: ln -sfn /home/app-user/deployments/app-name-{previous-job-id} /home/app-user/app/current
5. Start service with previous version: systemctl --user start app-name.service
6. Check health endpoint: curl http://localhost:8080/health
EOF
echo ""

# Show the notification process
echo "===== NOTIFICATION PROCESS ====="
cat << 'EOF'
1. Prepare notification message with deployment details:
   - Application name and version
   - Environment
   - Deployment status (success/failure)
   - Commit details
   - Pipeline URL
2. Send notification to the Notification Service
   - This is a generic service that can be configured to use various channels
   - Replaces the previous Slack-specific implementation
EOF
echo ""

# Show the key features of the pipeline
echo "===== KEY FEATURES ====="
echo "- Modular design for maintainability and reusability"
echo "- Focus on Java applications deployed with systemd services"
echo "- Multi-environment support (dev, test, staging, production)"
echo "- Automatic and manual deployment options"
echo "- Rollback capabilities (manual and automatic)"
echo "- Comprehensive logging and notifications"
echo "- Test mode for local testing without making actual changes"
echo "- Standardized British English throughout documentation and code"
echo "- Generic Notification Service integration (replacing Slack-specific implementation)"
echo "- Professional diagrams showing pipeline flow, deployment process, environment workflow, and rollback strategy"
echo ""

echo "===== DOCUMENTATION ====="
echo "- README.md: Overview of the pipeline and its features"
echo "- JAVA_QUICK_START.md: Quick start guide for Java applications"
echo "- JAVA_ENHANCEMENTS.md: Optional enhancements for Java applications"
echo "- LOCAL_TESTING.md: Guide for testing the pipeline locally"
echo "- diagrams/: Professional PlantUML diagrams showing pipeline flow and processes"
echo ""

echo "===== PIPELINE STRUCTURE AND FLOW EXPLANATION COMPLETE ====="
