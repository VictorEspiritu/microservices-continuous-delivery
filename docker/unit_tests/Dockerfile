FROM php:7.1-cli
RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y git zlib1g-dev && \
    docker-php-ext-install -j$(nproc) zip && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    chmod +x composer.phar && \
    mv composer.phar /usr/local/bin/composer
VOLUME /opt
WORKDIR /opt
ENTRYPOINT ["docker/unit_tests/run_tests.sh"]
