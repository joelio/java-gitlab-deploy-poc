# Testing the GitLab CI/CD Pipeline

![Rollback Strategy](diagrams/Rollback_Strategy.png)

*Comprehensive testing of rollback functionality*

## Overview

This document explains how to test the GitLab CI/CD pipeline to ensure it works correctly in all environments. Our testing philosophy is built on a fundamental principle:

> "The files we want to ship are the files under test, with no divergence from that end state."

This means we use the exact same CI files in both production and testing environments, ensuring complete consistency.

## Quick Start

To run all tests in sequence:

```bash
./tests/run_all_tests.sh
```

This will execute all tests from basic to comprehensive, providing clear feedback on each test's success or failure.

## Test Suite Components

| Test Type | Command | Purpose |
|-----------|---------|---------|
| Basic Structure | `./tests/test_pipeline.sh` | Validates pipeline structure and job dependencies |
| GitLab CI Local | `./tests/gitlab_ci_local_comprehensive.sh` | Tests all pipeline actions using gitlab-ci-local |
| Systemd Service | `./tests/test_systemd_rollback.sh` | Tests systemd service handling and rollback |
| Comprehensive | `./tests/comprehensive_pipeline_test.sh` | Full validation including edge cases and multi-server deployments |

## What Gets Tested

Our comprehensive test suite validates:

1. **Build and Deployment**
   - Artifact creation and packaging
   - Deployment to target environments
   - Directory structure creation
   - Symlink management

2. **Systemd Service Handling**
   - Service file creation
   - Service lifecycle (enable, start, stop)
   - Service status verification

3. **Rollback Functionality**
   - Manual rollback capability
   - Automatic rollback on failure
   - Multiple rollback versions
   - Service restart after rollback

4. **Multi-Server Deployments**
   - Sequential deployment to multiple servers
   - Consistent state across servers
   - Rollback across all servers

5. **Edge Cases**
   - Service failure handling
   - Invalid deployment recovery
   - Error reporting and notifications

## Testing Environments

All tests use containerized environments to ensure consistent testing:

- **GitLab CI Local**: Simulates the GitLab CI/CD environment locally
- **Podman with systemd**: Provides a real systemd environment for service testing
- **Multi-server simulation**: Tests deployment across multiple servers

## Troubleshooting

### Common Issues

1. **YAML Parsing Errors**
   - Check indentation in YAML files, especially in functions.yml
   - Ensure shell functions are properly indented within YAML structure

2. **Job Dependency Errors**
   - Verify job names match between dependencies
   - Check that all referenced jobs exist in the pipeline

3. **Systemd Container Issues**
   - Ensure container has privileged access
   - Mount /sys/fs/cgroup correctly
   - Run container with /sbin/init as PID 1

## Best Practices

When modifying the pipeline:

1. **Run all tests** before committing changes
2. **Maintain consistency** between test and production files
3. **Test edge cases** thoroughly
4. **Verify multi-server** functionality
5. **Check rollback** capabilities

## Contributing to Tests

When adding new tests:

1. Follow the existing pattern of using the exact same CI files
2. Add clear success/failure indicators
3. Document what's being tested
4. Ensure tests are idempotent and clean up after themselves

## Conclusion

Our testing approach ensures that the GitLab CI/CD pipeline is thoroughly validated using the exact same files that will be shipped to users. This guarantees that "the files we want to ship are the files under test, with no divergence from that end state."
