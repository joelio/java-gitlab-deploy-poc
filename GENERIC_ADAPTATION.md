# Adapting the Pipeline for Other Application Types

While this GitLab CI/CD pipeline is optimized for Java applications, it can be adapted for other application types with some modifications. This guide provides general instructions for adapting the pipeline to other runtime environments.

## General Adaptation Principles

1. **Keep the Modular Structure**: Maintain the separation of concerns with modular components
2. **Customize Build Process**: Modify the build commands for your specific runtime
3. **Adjust Artifact Handling**: Update artifact paths and patterns for your application type
4. **Configure Service**: Adapt the systemd service configuration for your runtime
5. **Update Health Checks**: Modify health check URLs and validation methods

## Configuration Variables to Modify

For any application type, you'll need to modify these key variables in `ci/variables.yml`:

```yaml
variables:
  # Application details
  APP_NAME: "your-application"
  APP_VERSION: "1.0.0"
  
  # Build configuration
  BUILD_COMMAND: "your-build-command"  # Modify this for your build system
  
  # Artifact settings
  ARTIFACT_PATH: "path/to/your/artifact"  # Modify for your build output
  ARTIFACT_NAME: "your-artifact-name"  # The name when deployed
  
  # Runtime configuration
  RUNTIME_PATH: "/path/to/runtime"  # Path to your runtime executable
  RUNTIME_OPTS: "runtime-options"  # Runtime-specific options
  
  # Service configuration
  START_COMMAND: "command-to-start-your-application"
  WORKING_DIRECTORY: "/path/to/app/directory"
  SERVICE_ENV_VARS: "ENV_VAR1=value1,ENV_VAR2=value2"
```

## Example Adaptations

### For Node.js Applications

```yaml
variables:
  # Build configuration
  BUILD_COMMAND: "npm ci && npm run build"
  
  # Artifact settings
  ARTIFACT_PATH: "dist/"
  ARTIFACT_NAME: "dist"
  
  # Runtime configuration
  RUNTIME_PATH: "/usr/bin/node"
  RUNTIME_OPTS: ""
  
  # Service configuration
  START_COMMAND: "/usr/bin/node /opt/app/current/index.js"
  WORKING_DIRECTORY: "/opt/app/current"
  SERVICE_ENV_VARS: "NODE_ENV=${CI_ENVIRONMENT_NAME},PORT=3000"
```

### For .NET Applications

```yaml
variables:
  # Build configuration
  BUILD_COMMAND: "dotnet publish -c Release"
  
  # Artifact settings
  ARTIFACT_PATH: "bin/Release/net6.0/publish/"
  ARTIFACT_NAME: "publish"
  
  # Runtime configuration
  RUNTIME_PATH: "/usr/bin/dotnet"
  RUNTIME_OPTS: ""
  
  # Service configuration
  START_COMMAND: "/usr/bin/dotnet /opt/app/current/YourApp.dll"
  WORKING_DIRECTORY: "/opt/app/current"
  SERVICE_ENV_VARS: "ASPNETCORE_ENVIRONMENT=${CI_ENVIRONMENT_NAME},ASPNETCORE_URLS=http://0.0.0.0:5000"
```

### For Python Applications

```yaml
variables:
  # Build configuration
  BUILD_COMMAND: "pip install -r requirements.txt && python setup.py bdist_wheel"
  
  # Artifact settings
  ARTIFACT_PATH: "dist/"
  ARTIFACT_NAME: "dist"
  
  # Runtime configuration
  RUNTIME_PATH: "/usr/bin/python3"
  RUNTIME_OPTS: "-u"
  
  # Service configuration
  START_COMMAND: "/opt/app/venv/bin/python -u /opt/app/current/app.py"
  WORKING_DIRECTORY: "/opt/app/current"
  SERVICE_ENV_VARS: "PYTHONUNBUFFERED=1,FLASK_ENV=${CI_ENVIRONMENT_NAME}"
```

## Modifying the Build Process

You'll need to modify the build job in `ci/build.yml` to match your application's build requirements:

```yaml
.build_template:
  stage: build
  script:
    - echo "Building ${APP_NAME} version ${APP_VERSION}"
    - ${BUILD_COMMAND}  # This will use your custom build command
    - echo "Build completed successfully"
  artifacts:
    paths:
      - ${ARTIFACT_PATH}  # This will use your custom artifact path
```

## Adapting the Deployment Process

The deployment process in `ci/deploy.yml` may need adjustments for your application type:

1. **Directory Structure**: Ensure the deployment directories match your application's needs
2. **Service Configuration**: Modify the systemd service template for your runtime
3. **Health Checks**: Update the health check mechanism to validate your application

## Adapting the Rollback Process

The rollback process in `ci/rollback.yml` is generally runtime-agnostic and should work with minimal changes.

## Testing Your Adaptation

After adapting the pipeline for your application type:

1. Set `CI_TEST_MODE: "true"` to simulate the pipeline without making actual changes
2. Run a test pipeline to verify your configuration
3. Check the logs for any errors or issues
4. Make adjustments as needed

## Maintaining the Core Principles

While adapting the pipeline, maintain these core principles:

1. **Modular Components**: Keep the separation of concerns with modular files
2. **Consistent Error Handling**: Maintain the error handling and logging approach
3. **Testing Philosophy**: Follow the principle that "the files we want to ship are the files under test"
4. **Security Practices**: Maintain secure handling of credentials and sensitive information

## Getting Help

If you need assistance adapting this pipeline for your specific application type, consult with your DevOps team or refer to the GitLab CI/CD documentation for your runtime environment.
