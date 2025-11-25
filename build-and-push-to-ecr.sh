#!/bin/bash
set -e

ECR_REPO="339713024768.dkr.ecr.us-west-2.amazonaws.com/isara-development-litellm-image"
REGION="us-west-2"
PROFILE="research-platform-dev/admin"

# Generate tags
GIT_SHA=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
VERSION_TAG="beta-fix-${TIMESTAMP}-${GIT_SHA}"

echo "Building and pushing LiteLLM to ECR..."
echo "Tags: latest, ${VERSION_TAG}"

# Verify fix is present
if grep -q "Strip beta query parameter for Bedrock" litellm/proxy/anthropic_endpoints/endpoints.py; then
    echo "✓ Beta query parameter fix verified"
else
    echo "✗ ERROR: Fix not found in endpoints.py"
    exit 1
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${REGION} --profile ${PROFILE} | \
    docker login --username AWS --password-stdin ${ECR_REPO}

# Build
echo "Building Docker image..."
docker build -t ${ECR_REPO}:latest -t ${ECR_REPO}:${VERSION_TAG} -f Dockerfile .

# Push
echo "Pushing images..."
docker push ${ECR_REPO}:latest
docker push ${ECR_REPO}:${VERSION_TAG}

echo "Done!"
echo "Latest tag: latest"
echo "Version tag: ${VERSION_TAG}"
echo "Deploy with: cd ~/isara/isara/infra/aws/research-platform && pulumi up"
