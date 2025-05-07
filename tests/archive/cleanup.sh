#!/bin/bash
# Script to clean up test environment

echo "Cleaning up test environment..."

# Remove test directories
rm -rf "$(pwd)/tests/mock-env"
rm -rf "$(pwd)/tests/sample-app/target"

echo "Test environment cleaned up."
