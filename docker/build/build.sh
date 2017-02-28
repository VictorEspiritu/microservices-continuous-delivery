#!/usr/bin/env bash

set -e

BUILD_DIRECTORY=/opt

APP_DIRECTORY=$BUILD_DIRECTORY/app
# Install non-dev dependencies
composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-interaction \
    --working-dir=$APP_DIRECTORY

mkdir -p $BUILD_DIRECTORY/docker
cp docker/service/Dockerfile $BUILD_DIRECTORY/docker
BUILD_TAR=$BUILD_DIRECTORY/docker/build.tar.gz
tar -czf $BUILD_TAR -C $APP_DIRECTORY .
