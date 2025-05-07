#!/bin/bash
# Test systemd service in a Docker container

set -e
echo "Testing systemd service in Docker container..."

# Create a test service file
cat > test-service.service << 'EOT'
[Unit]
Description=Test Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c 'while true; do echo "Service is running"; sleep 10; done'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Run a container with systemd
echo "Starting container with systemd..."
CONTAINER_ID=$(docker run -d --rm \
  --name systemd-test \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  registry.access.redhat.com/ubi8/ubi:latest \
  /sbin/init)

echo "Container started with ID: $CONTAINER_ID"

# Copy the service file to the container
docker cp test-service.service systemd-test:/etc/systemd/system/

# Enable and start the service
echo "Enabling and starting the service..."
docker exec systemd-test systemctl daemon-reload
docker exec systemd-test systemctl enable test-service
docker exec systemd-test systemctl start test-service

# Check the service status
echo "Checking service status..."
docker exec systemd-test systemctl status test-service

# Clean up
echo "Press Enter to stop the container and clean up..."
read
docker stop systemd-test
echo "Test completed and container stopped."
