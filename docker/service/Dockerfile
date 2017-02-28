FROM php:7.1-cli
ENTRYPOINT ["php", "-S", "0.0.0.0:80", "-t", "web/"]
STOPSIGNAL SIGINT
ADD ./build.tar.gz /opt
WORKDIR /opt
