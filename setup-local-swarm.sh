#!/usr/bin/env bash

    docker-machine create -d virtualbox manager1
    docker-machine create -d virtualbox worker1
    docker-machine create -d virtualbox worker2

    eval $(docker-machine env manager1)

    docker swarm init \
        --advertise-addr $(docker-machine ip manager1)

    WORKER_JOIN_TOKEN=$(docker swarm join-token -q worker)

    # Let the Docker client talk to `worker1`
    eval $(docker-machine env worker1)
    docker swarm join \
        --token $WORKER_JOIN_TOKEN \
        --advertise-addr $(docker-machine ip worker1) \
        $(docker-machine ip manager1):2377

    # Let the Docker client talk to `worker2`
    eval $(docker-machine env worker2)
    docker swarm join \
        --token $WORKER_JOIN_TOKEN \
        --advertise-addr $(docker-machine ip worker2) \
        $(docker-machine ip manager1):2377
