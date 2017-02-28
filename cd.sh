#!/usr/bin/env bash

# Exit this script upon the first failing command
set -e

if [ -z "$DOCKER_HUB_USERNAME" ]; then
    echo "You need to set the DOCKER_HUB_USERNAME environment variable"
    exit 1
fi

# Assumes Git >= 2.7
GIT_CLONE_URL="$(git remote get-url origin)"
COMMIT_HASH="$(git rev-parse --short --verify HEAD)"
# We assume the previous working directory to be the project root directory
PROJECT_DIR=$(pwd)

export TEST_IMAGE_TAG="$DOCKER_HUB_USERNAME/service:$COMMIT_HASH"
RELEASE_IMAGE_TAG="$DOCKER_HUB_USERNAME/service:latest"

function fresh_checkout() {
    cd "$PROJECT_DIR"
    BUILD_DIR="$PROJECT_DIR/build/$COMMIT_HASH"
    rm -rf "$BUILD_DIR" 2> /dev/null || true
    mkdir -p "$BUILD_DIR"
    git clone "$GIT_CLONE_URL" "$BUILD_DIR"
    cd "$BUILD_DIR"
    git checkout "$COMMIT_HASH"
}

#----------------------------------------------------
# Build the test container and run the unit tests
#----------------------------------------------------
fresh_checkout

docker build \
    -t "$DOCKER_HUB_USERNAME/unit_tests" \
    -f docker/unit_tests/Dockerfile \
    ./
docker run \
    --rm \
    -t \
    -v "$BUILD_DIR:/opt" \
    -v "$HOME/.composer:/home/.composer" \
    "$DOCKER_HUB_USERNAME/unit_tests"

#----------------------------------------------------
# Build the build container and run the build
#----------------------------------------------------
fresh_checkout

docker build \
    -t "$DOCKER_HUB_USERNAME/build" \
    -f "docker/build/Dockerfile" \
    ./
docker run \
    --rm  \
    -t \
    -v "$BUILD_DIR:/opt" \
    -v "$HOME/.composer:/home/.composer" \
    "$DOCKER_HUB_USERNAME/build"
docker build \
    -t "$TEST_IMAGE_TAG" \
    "$BUILD_DIR/docker"

#----------------------------------------------------
# Build the service_test containers and start them
#----------------------------------------------------
docker_compose_service_tests="docker-compose -f docker-compose.service_tests.yml"
$docker_compose_service_tests build
$docker_compose_service_tests up -d

#----------------------------------------------------
# Run service tests and stop all services
#----------------------------------------------------
$docker_compose_service_tests run service_tests all
$docker_compose_service_tests down

#----------------------------------------------------
# Release the new image of the service
#----------------------------------------------------
docker tag "$TEST_IMAGE_TAG" "$RELEASE_IMAGE_TAG"
docker push "$RELEASE_IMAGE_TAG"

#----------------------------------------------------
# Deploy
#----------------------------------------------------

eval "$(docker-machine env manager1)"

# Deploy to the Swarm
docker stack deploy \
    --compose-file "$BUILD_DIR/docker-compose.deploy.yml" \
    cd_demo

###
echo "Visit the newly deployed service at http://$(docker-machine ip manager1)/"
echo "Press enter to start watching the deploy process"
read -r
###

watch docker stack ps cd_demo
