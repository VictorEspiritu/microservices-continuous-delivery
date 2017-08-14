#!/usr/bin/env bash

# Exit this script upon the first failing command
set -e

if [ -z "${DOCKER_HUB_USERNAME}" ]; then
    echo "You need to set the DOCKER_HUB_USERNAME environment variable"
    exit 1
fi

# Find out the URL of the "origin" repository
GIT_CLONE_URL="$(git remote get-url origin)"

# Find out the latest commit hash
COMMIT_HASH="$(git rev-parse --short --verify HEAD)"

# We assume the previous working directory to be the project root directory
PROJECT_DIR=$(pwd)

export TEST_IMAGE_TAG="${DOCKER_HUB_USERNAME}/service:${COMMIT_HASH}"
export RELEASE_IMAGE_TAG="${DOCKER_HUB_USERNAME}/service:latest"

function fresh_checkout() {
    cd "${PROJECT_DIR}"
    mkdir -p "${PROJECT_DIR}/build"
    BUILD_DIR=$(mktemp -d "${PROJECT_DIR}/build/${COMMIT_HASH}-XXXXXXX")
    git clone "${GIT_CLONE_URL}" "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    git checkout "${COMMIT_HASH}"
}

function clean_up() {
    if [ ! -z "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}" || true
    fi
}

#----------------------------------------------------
# Build the test container and run the unit tests
#----------------------------------------------------
fresh_checkout

docker build \
    -t "${DOCKER_HUB_USERNAME}/unit_tests" \
    -f docker/unit_tests/Dockerfile \
    "${BUILD_DIR}"
docker run \
    -u "${UID}" \
    --rm \
    -t \
    -v "${BUILD_DIR}:/opt" \
    -v "${HOME}/.composer:/home/.composer" \
    "${DOCKER_HUB_USERNAME}/unit_tests"

clean_up

#----------------------------------------------------
# Build the build container and run the build
#----------------------------------------------------
fresh_checkout

docker build \
    -t "${DOCKER_HUB_USERNAME}/build" \
    -f "docker/build/Dockerfile" \
    "${BUILD_DIR}"
docker run \
    -u "${UID}" \
    --rm  \
    -t \
    -v "${BUILD_DIR}:/opt" \
    -v "${HOME}/.composer:/home/.composer" \
    "${DOCKER_HUB_USERNAME}/build"
docker build \
    -t "${TEST_IMAGE_TAG}" \
    "${BUILD_DIR}/docker/service"

#----------------------------------------------------
# Build the service_test containers and start them
#----------------------------------------------------
docker_compose_service_tests="docker-compose -f docker-compose.service_tests.yml"
${docker_compose_service_tests} build
${docker_compose_service_tests} up -d

#----------------------------------------------------
# Run service tests and stop all services
#----------------------------------------------------
${docker_compose_service_tests} run service_tests
${docker_compose_service_tests} down

#----------------------------------------------------
# Release the new image of the service
#----------------------------------------------------
docker tag "${TEST_IMAGE_TAG}" "${RELEASE_IMAGE_TAG}"
docker push "${RELEASE_IMAGE_TAG}"

#----------------------------------------------------
# Deploy
#----------------------------------------------------

eval "$(docker-machine env manager1)"

# Deploy to the Swarm
docker stack deploy \
    --compose-file "${BUILD_DIR}/docker-compose.deploy.yml" \
    cd_demo

# clean_up

###
echo "Visit the newly deployed service at http://$(docker-machine ip manager1)/"
echo "Press enter to start watching the deploy process"
read -r
###

watch docker stack ps cd_demo
