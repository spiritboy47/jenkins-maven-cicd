#!/bin/bash

DOCKERHUB_NAMESPACE="username"
REPO_NAME="repo-name"

# Navigate to the workspace directory
cd "$WORKSPACE" || exit 1

# Ensure Dockerfile exists
if [ ! -f Dockerfile ]; then
    echo "Error: Dockerfile not found in $WORKSPACE"
    exit 1
fi

# Get the short Git commit hash
SHORT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
if [ "$SHORT_COMMIT" == "unknown" ]; then
    echo "Warning: Unable to determine Git commit hash. Using 'latest'."
    SHORT_COMMIT="latest"
fi

# Build the Docker image name
IMAGE_NAME="${DOCKERHUB_NAMESPACE}/${REPO_NAME}:${SHORT_COMMIT}"

# Build the Docker image
echo "Building Docker image: $IMAGE_NAME"
docker build --memory=4g --memory-swap=4g --no-cache --progress=plain \
    -t "${IMAGE_NAME}" --file Dockerfile . || {
    echo "Error: Docker image build failed."
    exit 1
}

# Login to Docker Hub
echo "Logging in to Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin || {
    echo "Error: Docker Hub login failed."
    exit 1
}

# Push the Docker image to Docker Hub
echo "Pushing Docker image to Docker Hub: $IMAGE_NAME"
docker push "${IMAGE_NAME}" || {
    echo "Error: Docker image push failed."
    exit 1
}

# Optional: Clean up local Docker images
echo "Cleaning up local Docker image: $IMAGE_NAME"
docker rmi "${IMAGE_NAME}" || {
    echo "Warning: Failed to remove local Docker image."
}

echo "Docker image build and push process completed successfully."

