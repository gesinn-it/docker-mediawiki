###################################################
# gesinn-it/mediawiki:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache
#
# MEDIAWIKI_VERSION: MediaWiki Version
# PHP_VERSION: PHP Version
# XDEBUG_VERSION: Xdebug Version
###################################################
ARG MEDIAWIKI_VERSION=1.45.1
ARG PHP_VERSION=8.3
ARG COMPOSER_VERSION=2.9.2

FROM composer:${COMPOSER_VERSION} AS composer

FROM gesinn/mediawiki-base:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache AS mediawiki

# Bashrc Alias
RUN echo "alias ll='ls -la'" >> /etc/bash.bashrc && \
    echo "alias ..='cd ..'" >> /etc/bash.bashrc && \
    echo "alias ...='cd ...'" >> /etc/bash.bashrc

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    sudo \
    unzip \
    less \
    nano \
    nodejs \
    grunt \
    npm \
    wget \
    default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Install required php extensions
RUN docker-php-ext-install pdo_mysql

# Install Composer
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN echo "{}" > composer.local.json && \
    COMPOSER=composer.local.json composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true && \
	COMPOSER=composer.local.json composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true && \
    COMPOSER=composer.local.json composer config --no-plugins allow-plugins.composer/installers true

# RUN composer update \
#     --no-dev \
#     --prefer-dist \
#     --no-interaction \
#     --no-progress \
#     --no-scripts

# TEMPORARY: Composer >=2.4 blocks builds on dev-only security advisories
# (e.g. PHPUnit) even when running with --no-dev.
# This image intentionally excludes all dev dependencies, so disabling
# the audit here is safe. Remove once MediaWiki updates its dev constraints.
RUN composer config --global audit.block-insecure false && \
    composer update \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --no-scripts

###################################################
# gesinn-it/mediawiki-ci:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache
###################################################
FROM mediawiki AS mediawiki-ci

ARG XDEBUG_VERSION=3.3.2

### add build tools and patches folder
RUN curl -LJ https://github.com/gesinn-it-pub/docker-mediawiki-tools/tarball/3.2.1 \
	| tar xzC / --strip-components 1

RUN chmod +x /build-tools/* /tools/*
ENV PATH="/tools:/build-tools:${PATH}"

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Install XDebug
RUN pecl install xdebug-${XDEBUG_VERSION} \
 && rm -rf /tmp/pear

# Configure Xdebug
RUN echo 'zend_extension=xdebug' >> /usr/local/etc/php/conf.d/99-xdebug.ini
RUN echo 'xdebug.mode=coverage' >> /usr/local/etc/php/conf.d/99-xdebug.ini

# Install required php extensions (required for CI)
RUN docker-php-ext-install pgsql

# RUN composer update \
#     --prefer-dist \
#     --no-interaction \
#     --no-progress

# TEMPORARY: Composer blocks dependency resolution due to dev-only
# security advisories (e.g. PHPUnit). This does not affect runtime
# dependencies. Remove once MediaWiki updates its dev constraints.
RUN composer config --global audit.block-insecure false && \
    composer update \
    --prefer-dist \
    --no-interaction \
    --no-progress
