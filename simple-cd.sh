#!/bin/bash

# Ensure cron can find docker and aws commands
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


REGION="your-region-here"
REGISTRY_ID="123456789012"
IMAGE_TAG="latest"
ECR_BASE="${REGISTRY_ID}.dkr.ecr.${REGION}.amazonaws.com"

update_service() {
    local REPO_NAME=$1
    local CONTAINER_NAME=$2
    local PORT_MAPPING=$3
    local FULL_IMAGE_URL="${ECR_BASE}/${REPO_NAME}:${IMAGE_TAG}"

    echo "-------------------------------------------"
    echo "$(date): Checking $REPO_NAME"

    # Get remote digest
    REMOTE_DIGEST=$(aws ecr describe-images --repository-name "$REPO_NAME" --image-ids imageTag="$IMAGE_TAG" --query 'imageDetails[0].imageDigest' --output text 2>/dev/null)

    if [ "$REMOTE_DIGEST" = "None" ] || [ -z "$REMOTE_DIGEST" ]; then
        echo "error: Image not found in ECR: $REPO_NAME"
        return
    fi

    # Get local image digest
    LOCAL_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$CONTAINER_NAME" 2>/dev/null | cut -d'@' -f2)

    # 3. Compare and Action
    if [ "$REMOTE_DIGEST" = "$LOCAL_DIGEST" ]; then
        echo "[$CONTAINER_NAME] matches ECR digest. No update needed."
    else
        echo "[$CONTAINER_NAME] New version detected! Updating"
        
        # Login and pull
        aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_BASE"
        docker pull "$FULL_IMAGE_URL"
        
        # Stop and restart
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        docker run -d --name "$CONTAINER_NAME" $PORT_MAPPING "$FULL_IMAGE_URL"
        
        echo "[$CONTAINER_NAME] update complete."
    fi
}


# update_service "<ECR_REPO_NAME>" "<LOCAL_CONTAINER_NAME>" "<PORT_MAPPING>"
update_service "app-dashboard/backend" "app-backend" "-p 8080:8080"
update_service "app-dashboard/frontend" "app-frontend" "-p 80:80"
