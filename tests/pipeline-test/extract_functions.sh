#!/bin/bash
set -e

# Extract the shell functions from functions.yml
yq -r '.script[0]' < functions.yml > functions.sh
chmod +x functions.sh
echo "Functions extracted successfully."
