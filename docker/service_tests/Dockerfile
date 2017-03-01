FROM alpine:3.5
RUN apk add --no-cache curl bash
RUN mkdir /opt
COPY ./run_tests.sh /opt
ENTRYPOINT ["sh", "/opt/run_tests.sh"]
