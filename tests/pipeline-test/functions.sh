#!/bin/bash

create_deployment_dir() {
    mkdir -p "$DEPLOY_DIR/$APP_NAME/$APP_VERSION"
    echo "Created deployment directory at $DEPLOY_DIR/$APP_NAME/$APP_VERSION"
}

create_symlink() {
    ln -sfn "$DEPLOY_DIR/$APP_NAME/$APP_VERSION" "$BASE_PATH/$APP_NAME/current"
    echo "Created symlink from $DEPLOY_DIR/$APP_NAME/$APP_VERSION to $BASE_PATH/$APP_NAME/current"
}

deploy_to_servers() {
    echo "Deploying to servers: $DEPLOY_HOST"
    mkdir -p "$DEPLOY_DIR/$APP_NAME/$APP_VERSION"
    mkdir -p "$BASE_PATH/$APP_NAME"
    cp "$ARTIFACT_PATH/$ARTIFACT_NAME" "$DEPLOY_DIR/$APP_NAME/$APP_VERSION/"
    echo "Application deployed to $DEPLOY_DIR/$APP_NAME/$APP_VERSION"
}

setup_service() {
    echo "Setting up systemd service"
    cp "systemd-test.service" "$CONFIG_DIR/$APP_NAME.service"
    systemctl daemon-reload
    systemctl enable "$APP_NAME.service"
    echo "Service setup complete"
}

start_service() {
    echo "Starting service"
    systemctl start "$APP_NAME.service"
    echo "Service started"
}

check_service_status() {
    echo "Checking service status"
    systemctl status "$APP_NAME.service"
}

stop_service() {
    echo "Stopping service"
    systemctl stop "$APP_NAME.service"
    echo "Service stopped"
}

rollback_deployment() {
    echo "Rolling back to previous version"
    local previous_version=$(find "$DEPLOY_DIR/$APP_NAME" -maxdepth 1 -type d -not -name "current" -not -name "$APP_VERSION" | sort -r | head -1 | xargs basename)
    if [ -z "$previous_version" ]; then
        echo "No previous version found to rollback to"
        return 1
    fi
    stop_service
    echo "Rolling back from $APP_VERSION to $previous_version"
    export APP_VERSION="$previous_version"
    create_symlink
    start_service
    echo "Rollback complete"
}
