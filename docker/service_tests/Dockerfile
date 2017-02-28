FROM alpine:3.5

# Install ncat
RUN apk add --no-cache curl bash

VOLUME /opt
WORKDIR /opt

ENTRYPOINT ["docker/service_tests/run_tests.sh"]
