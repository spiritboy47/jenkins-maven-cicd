#!/bin/bash

# ===== CONFIGURATION =====
DOCKERHUB_NAMESPACE="dockernamespace"
REPO_NAME="b2b-auth-migration"  # 👈 CHANGE THIS per Jenkins job (e.g. b2b-apigateway-migration)
COMPOSE_DIR="/home/tech/b2b"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"
BACKUP_DIR="${COMPOSE_DIR}/backup"
COMMIT_DIR="${COMPOSE_DIR}/last-commits"

# ===== PREPARE PATHS =====
mkdir -p "$BACKUP_DIR"
mkdir -p "$COMMIT_DIR"
BACKUP_SUFFIX=$(date +%F-%H-%M-%S)
COMMIT_FILE="${COMMIT_DIR}/${REPO_NAME}.commit"

# ===== VERIFY DOCKERFILE =====
cd "$WORKSPACE" || { echo "❌ Error: Cannot access workspace"; exit 1; }

if [ ! -f Dockerfile ]; then
    echo "❌ Error: Dockerfile not found in $WORKSPACE"
    exit 1
fi

# ===== GET GIT COMMIT HASH =====
SHORT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

if [[ "$SHORT_COMMIT" == "unknown" ]]; then
    echo "⚠️  Warning: Commit hash not found. Proceeding with 'latest' as fallback."
    SHORT_COMMIT="latest"
fi

# ===== SKIP IF COMMIT IS SAME =====
if [[ -f "$COMMIT_FILE" ]]; then
    LAST_COMMIT=$(cat "$COMMIT_FILE")
    if [[ "$SHORT_COMMIT" == "$LAST_COMMIT" ]]; then
        echo "🔁 Skipping build: Commit $SHORT_COMMIT already deployed for ${REPO_NAME}."
        exit 0
    fi
fi

# ===== BUILD DOCKER IMAGE =====
IMAGE_NAME="${DOCKERHUB_NAMESPACE}/${REPO_NAME}:${SHORT_COMMIT}"
echo "🐳 Building Docker image: $IMAGE_NAME"

docker build --memory=4g --memory-swap=4g --no-cache --progress=plain \
    -t "${IMAGE_NAME}" -f Dockerfile . || {
    echo "❌ Error: Docker build failed"
    exit 1
}


# ===== PUSH TO DOCKER HUB =====
echo "🔐 Logging in to Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin || {
    echo "❌ Error: Docker Hub login failed"
    exit 1
}

echo "📤 Pushing image to Docker Hub..."
docker push "${IMAGE_NAME}" || {
    echo "❌ Error: Docker image push failed"
    exit 1
}

# ===== BACKUP COMPOSE FILE =====
BACKUP_FILE="${BACKUP_DIR}/docker-compose.yml.bak_${REPO_NAME}_${BACKUP_SUFFIX}"
echo "🧾 Creating backup at $BACKUP_FILE"
cp "${COMPOSE_FILE}" "${BACKUP_FILE}" || {
    echo "❌ Error: Backup failed"
    exit 1
}

# ===== UPDATE docker-compose.yml =====
echo "🛠️  Updating image tag in docker-compose.yml..."
sed -i "s|${DOCKERHUB_NAMESPACE}/${REPO_NAME}:[a-zA-Z0-9_.-]\+|${IMAGE_NAME}|g" "${COMPOSE_FILE}" || {
    echo "❌ Error: Failed to update docker-compose.yml"
    exit 1
}

# ===== REDEPLOY SERVICES =====
cd "$COMPOSE_DIR" || {
    echo "❌ Error: Cannot access compose directory"
    exit 1
}

echo "🚀 Pulling new image and restarting service..."
docker-compose pull && docker-compose up -d || {
    echo "❌ Error: Docker Compose deployment failed"
    exit 1
}

# ===== UPDATE LAST COMMIT FILE =====
echo "$SHORT_COMMIT" > "$COMMIT_FILE"

# ===== CLEANUP LOCAL IMAGE (optional) =====
#docker rmi "${IMAGE_NAME}" || echo "⚠️  Warning: Failed to remove local image"

# ===== DONE =====
echo "✅ Deployment complete for ${REPO_NAME} with image tag ${SHORT_COMMIT}"
