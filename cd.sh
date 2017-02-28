#!/usr/bin/env bash

# Exit this script upon the first failing command
set -e

# Run with local Docker Engine
eval $(docker-machine env -u)

GIT_CLONE_URL="git@gitlab.com:matthiasnoback/independent-deployability.git"
BUILD_REFERENCE="$(git rev-parse --short --verify HEAD)"

export TEST_IMAGE_TAG="$DOCKER_HUB_USERNAME/service:$BUILD_REFERENCE"
RELEASE_IMAGE_TAG="$DOCKER_HUB_USERNAME/service:latest"

BUILD_DIR="$(pwd)/build/$BUILD_REFERENCE"
rm -r $BUILD_DIR || true
git clone "$GIT_CLONE_URL" "$BUILD_ROOT"
cd $BUILD_DIR

#----------------------------------------------------
# Build the test container and run the unit tests
#----------------------------------------------------
docker build \
    -t $DOCKER_HUB_USERNAME/unit_tests \
    -f docker/unit_tests/Dockerfile \
    ./
docker run \
    --rm \
    -t \
    -v $BUILD_DIR:/opt \
    $DOCKER_HUB_USERNAME/unit_tests

#----------------------------------------------------
# Build the build container and run the build
#----------------------------------------------------
docker build \
    -t $DOCKER_HUB_USERNAME/build \
    -f docker/build/Dockerfile \
    ./
docker run \
    --rm  \
    -t \
    -v $BUILD_DIR:/opt \
    $DOCKER_HUB_USERNAME/build
docker build \
    -t $TEST_IMAGE_TAG \
    $BUILD_DIR/docker

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
docker tag $TEST_IMAGE_TAG $RELEASE_IMAGE_TAG
docker push $RELEASE_IMAGE_TAG

#----------------------------------------------------
# Deploy
#----------------------------------------------------

eval $(docker-machine env manager1)

# Deploy to the Swarm
docker stack deploy \
    --compose-file $BUILD_DIR/docker-compose.deploy.yml \
    cd_demo

###
echo "Visit the newly deployed service at http://$(docker-machine ip manager1)/"
echo "Press enter to start watching the deploy process"
read
###

watch docker stack ps cd_demo
