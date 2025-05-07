#!/bin/bash
# This script extracts the shell functions from the functions.yml file
# and makes them available to our test jobs

# Extract the shell functions from the functions.yml file
# Skip the YAML header and just get the shell functions
sed -n '/^  # Common utility functions/,$p' ../ci/functions.yml | sed 's/^  //' > /tmp/functions.sh

# Make the functions available
source /tmp/functions.sh
