# Testing the GitLab CI/CD Pipeline Blueprint

![Rollback Strategy](../diagrams/Rollback%20Strategy.png)

## Overview

This directory contains a comprehensive testing framework for the GitLab CI/CD pipeline blueprint. Our testing philosophy is built on a fundamental principle:

> "The files we want to ship are the files under test, with no divergence from that end state."

This means we use the exact same CI files in both production and testing environments, ensuring complete consistency between what we test and what users receive.

## Prerequisites

To test the pipeline, you'll need:

- **gitlab-ci-local** (for pipeline testing)
  ```bash
  npm install -g gitlab-ci-local
  ```
- **Podman** (for systemd testing)
  ```bash
  # macOS
  brew install podman
  podman machine init
  podman machine start
  
  # Linux
  sudo dnf install podman   # RHEL/Fedora
  sudo apt install podman   # Debian/Ubuntu
  ```

## Testing Options

We provide several testing scripts with increasing levels of coverage:

### 1. Basic Pipeline Testing

```bash
./tests/test_pipeline.sh
```

This script:
- Creates a temporary directory
- Copies the exact CI files from `/ci/` to this directory (no modifications)
- Creates a test `.gitlab-ci.yml` file that includes these files
- Runs gitlab-ci-local with this configuration

### 2. Systemd Service Testing

```bash
./tests/test_systemd_rollback.sh
```

This script:
- Sets up a systemd-capable container using Podman
- Uses the exact same CI files from `/ci/` (no modifications)
- Tests systemd service handling and basic rollback functionality

### 3. Comprehensive Pipeline Testing

```bash
./tests/comprehensive_pipeline_test.sh
```

This script provides the most thorough testing, including:
- Basic deployment with systemd
- Rollback functionality (including multiple rollbacks)
- Edge cases (service failure handling)
- Multi-server deployment simulation
- Full service lifecycle testing

All tests use the exact same files that will be shipped to users, guaranteeing that "the files we want to ship are the files under test" with no divergence.

## Testing Specific Jobs

To run specific jobs in the pipeline:

```bash
./tests/test_pipeline.sh test deploy
```

This will run only the `test` and `deploy` jobs.

## Key Testing Principles

1. **Same files in production and testing**: We use the exact same CI files in both environments.
2. **Extended templates**: We've converted YAML anchors to `extends` for better compatibility.
3. **Complete testing**: We test the entire pipeline, including systemd service handling and rollback.
4. **Edge case coverage**: We test failure scenarios and recovery mechanisms.
5. **Multi-server support**: We validate deployment across multiple servers.

## Test Scripts

| Script | Purpose | Key Features |
|--------|---------|-------------|
| `run_all_tests.sh` | **Main test driver** | Orchestrates all tests in sequence with clear reporting |
| `test_pipeline.sh` | Structure validation | Tests basic pipeline structure with original CI files |
| `gitlab_ci_local_comprehensive.sh` | Functional testing | Tests builds, deployments, services and rollbacks using GitLab CI Local |
| `test_systemd_rollback.sh` | Service testing | Validates systemd service handling and rollback in containers |
| `comprehensive_pipeline_test.sh` | Complete validation | Covers all scenarios including edge cases and multi-server deployments |
| `convert_to_extends.sh` | YAML maintenance | Converts YAML anchors to `extends` for better compatibility |
| `podman_systemd_test.sh` | Container helper | Provides systemd testing in containers |

All testing scripts follow our guiding principle that "the files we want to ship are the files under test." Each script carefully uses the original CI files without modification.

## Running All Tests

For comprehensive validation, use the main test driver script:

```bash
./tests/run_all_tests.sh
```

This script will:
1. Run all tests in sequence, from basic to comprehensive
2. Report success or failure for each test
3. Provide clear feedback on test results
4. Ensure all aspects of the pipeline are tested

The test driver follows our core testing principle:
> "The files we want to ship are the files under test, with no divergence from that end state."

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure all scripts are executable:
   ```bash
   chmod +x tests/*.sh
   ```

2. **Podman Not Installed**: For systemd testing, ensure Podman is installed and running:
   ```bash
   podman machine start
   ```

3. **gitlab-ci-local Not Found**: Make sure gitlab-ci-local is installed globally:
   ```bash
   npm install -g gitlab-ci-local
   ```

4. **Systemd Not Running**: If systemd tests fail, ensure your container is privileged and has /sys/fs/cgroup mounted.
