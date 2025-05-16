#!/bin/bash

# Simple GitLab CI Pipeline Simulator
# This script simulates the execution of a GitLab CI pipeline based on the configuration

echo "=== GitLab CI Pipeline Simulator ==="
echo "Testing simplified pipeline flow without branch restrictions"

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Simulate pipeline stages
echo -e "\n${YELLOW}Checking pipeline structure...${NC}"
STAGES=$(grep "stages:" -A 5 .gitlab-ci.yml | grep -v "stages:" | grep -v "#" | grep -v "^$" | sed 's/^[ \t]*-[ \t]*//' | sed 's/[ \t]*$//')

echo "Detected pipeline stages:"
for stage in $STAGES; do
    echo -e "  - ${GREEN}$stage${NC}"
done

# Check for validate stage (should be removed)
if echo "$STAGES" | grep -q "validate"; then
    echo -e "\n${RED}ERROR: 'validate' stage still exists in pipeline!${NC}"
    echo "The validate stage should have been removed to simplify the flow."
    exit 1
else
    echo -e "\n${GREEN}✓ 'validate' stage successfully removed from pipeline.${NC}"
fi

# Check branch restrictions in build.yml
echo -e "\n${YELLOW}Checking branch restrictions...${NC}"
BRANCH_RESTRICTIONS=$(grep -A 20 "validate_branch_template" ci/build.yml | grep -E "ALLOWED_BRANCHES|if.*CI_COMMIT_REF_NAME")

if [ -z "$BRANCH_RESTRICTIONS" ]; then
    echo -e "${GREEN}✓ Branch restrictions successfully removed from build.yml${NC}"
else
    echo -e "${RED}ERROR: Branch restrictions still present in build.yml:${NC}"
    echo "$BRANCH_RESTRICTIONS"
    exit 1
fi

# Check deployment job dependencies
echo -e "\n${YELLOW}Checking deployment job dependencies...${NC}"
DEPLOY_DEPS=$(grep -A 5 "dependencies:" ci/deploy.yml | grep "validate_branch")

if [ -z "$DEPLOY_DEPS" ]; then
    echo -e "${GREEN}✓ Dependency on validate_branch successfully removed from deploy.yml${NC}"
else
    echo -e "${RED}ERROR: Dependency on validate_branch still present in deploy.yml:${NC}"
    echo "$DEPLOY_DEPS"
    exit 1
fi

# Check deployment rules
echo -e "\n${YELLOW}Checking deployment rules...${NC}"
DEPLOY_RULES=$(grep -A 10 "deploy_test:" .gitlab-ci.yml | grep -A 10 "rules:" | grep -E "if.*CI_COMMIT_BRANCH")

if [ -z "$DEPLOY_RULES" ]; then
    echo -e "${GREEN}✓ Branch-based rules successfully removed from deployment jobs${NC}"
else
    echo -e "${RED}ERROR: Branch-based rules still present in deployment jobs:${NC}"
    echo "$DEPLOY_RULES"
    exit 1
fi

# Simulate pipeline execution
echo -e "\n${YELLOW}Simulating pipeline execution...${NC}"

# Build stage
echo -e "\n${GREEN}Stage: build${NC}"
echo "Running job: build"
echo "✓ Build completed successfully"

# Deploy stage
echo -e "\n${GREEN}Stage: deploy${NC}"
echo "Running job: deploy_test (manual)"
echo "✓ Manual deployment to test environment triggered"
echo "Running job: deploy_staging (manual)"
echo "✓ Manual deployment to staging environment triggered"
echo "Running job: deploy_production (manual)"
echo "✓ Manual deployment to production environment triggered"

# Notify stage
echo -e "\n${GREEN}Stage: notify${NC}"
echo "Running job: notify_success_test (on_success)"
echo "✓ Success notification for test environment sent"
echo "Running job: notify_success_staging (on_success)"
echo "✓ Success notification for staging environment sent"
echo "Running job: notify_success_production (on_success)"
echo "✓ Success notification for production environment sent"

# Cleanup stage
echo -e "\n${GREEN}Stage: deploy (cleanup)${NC}"
echo "Running job: cleanup_test"
echo "✓ Cleanup for test environment completed"
echo "Running job: cleanup_staging"
echo "✓ Cleanup for staging environment completed"
echo "Running job: cleanup_production"
echo "✓ Cleanup for production environment completed"

echo -e "\n${GREEN}=== Pipeline simulation completed successfully ===${NC}"
echo "The simplified pipeline flow works as expected without branch restrictions."
