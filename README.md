# Continuous Deployment Script

A lightweight bash script designed to run as a cron job on a development or testing server. It simulates Continuous Deployment by periodically checking AWS Elastic Container Registry (ECR) for new container image versions and automatically updating running local containers if a new image is found.

## How It Works

The script performs the following steps for each configured service:

1. **Remote Digest Check:** It uses the AWS CLI to fetch the latest `imageDigest` for the specified `IMAGE_TAG` from your ECR repository.
2. **Local Digest Check:** It uses Docker to inspect the currently running container and retrieves its image digest.
3. **Compare & Update:**
   - If the remote and local digests match, no action is taken.
   - If they differ (a new image was pushed to ECR), it logs into ECR, pulls the new image, stops and removes the existing container, and starts a new container with the updated image using your provided port mappings.

## Requirements

For this script to work properly, the host server must have:

1. **Docker**: Installed and running. The user executing the script (or cron job) must have permission to run docker commands (e.g., added to the `docker` group).
2. **AWS CLI**: Installed and configured.
3. **IAM Permissions**: The server needs AWS credentials (via instance profile, IAM role, or `aws configure`) with at least the following permissions to interact with ECR:
   - `ecr:GetAuthorizationToken`
   - `ecr:BatchCheckLayerAvailability`
   - `ecr:GetDownloadUrlForLayer`
   - `ecr:BatchGetImage`
   - `ecr:DescribeImages`
4. **Cron Job**: Set up a cron job to run the script automatically at your desired interval.
   *Example: Run every 5 minutes*

   ```bash
   */5 * * * * /path/to/Continuous_Deployment_Script/simple-cd.sh >> /var/log/simple-cd.log 2>&1
   ```

## What Needs to Be Changed

Before running the script, you must update it with your specific environment details. Open `simple-cd.sh` and modify the following variables:

### 1. Configuration Section (Lines 7-9)

Update these global variables to match your AWS environment:

- `REGION`: Your AWS region (e.g., `"us-east-1"`).
- `REGISTRY_ID`: Your 12-digit AWS Account ID where the ECR registry is hosted (e.g., `"123456789012"`).
- `IMAGE_TAG`: The image tag you want to track (default is `"latest"`).

### 2. Execution Section (Lines 52+)
At the bottom of the script, define the services you want to keep updated by calling the `update_service` function.

Format:

```bash
update_service "ECR_REPO_NAME" "LOCAL_CONTAINER_NAME" "PORT_MAPPING_AND_OTHER_DOCKER_RUN_ARGS"
```

Modify or add rows based on your containers. For example:

```bash
update_service "my-company/backend-api" "backend-api-container" "-p 8080:8080 -e ENV=dev"
update_service "my-company/frontend-web" "frontend-web-container" "-p 80:80"
```
