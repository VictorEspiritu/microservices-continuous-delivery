#!/usr/bin/env bash

set -e

if [ ! -t 1 ] ; then
    echo "To run the service tests, run this container with a terminal"
    exit 0
fi

function fail() {
    echo "Assertion failed. $1"
    exit 1
}

function finish() {
    echo "All tests passed"
    exit 0
}

function assertEquals() {
    if [[ "$1" != "$2" ]]; then
        fail "${3:-}"
    fi
}

server_output=$(curl --fail http://service/ 2> /dev/null)
assertEquals "0" "$?" "curl returned a non-zero exit code"
assertEquals "Continuous delivery is great!" "$server_output" "Server response did not match expected response"

finish
