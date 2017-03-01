#!/usr/bin/env bash

# Fail script upon first failed command
set -e

cd ./app

# Install development-specific dependencies
composer install --prefer-dist

# Run the unit tests
vendor/bin/phpunit
