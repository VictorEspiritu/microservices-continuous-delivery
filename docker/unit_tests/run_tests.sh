#!/usr/bin/env bash

# Fail script upon first failed command
set -e

cd ./app

# Install dev dependencies
composer install \
    --prefer-dist

# Run unit tests
vendor/bin/phpunit
