###################################################
# gesinn-it/mediawiki:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache
#
# MEDIAWIKI_VERSION: MediaWiki Version
# PHP_VERSION: PHP Version
###################################################
ARG MEDIAWIKI_VERSION
ARG PHP_VERSION

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
COPY --from=composer:2.1 /usr/bin/composer /usr/local/bin/composer

RUN composer update

###################################################
# gesinn-it/mediawiki-ci:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache
###################################################
FROM mediawiki AS mediawiki-ci

### add build tools and patches folder
RUN curl -LJ https://github.com/gesinn-it-pub/docker-mediawiki-tools/tarball/1.7.4 \
	| tar xzC / --strip-components 1

RUN chmod +x /build-tools/* /tools/*
ENV PATH="/tools:/build-tools:${PATH}"

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Install XDebug
# ToDo: remove/adapt version pinning for newer PHP versions
RUN pecl install xdebug-3.1.6

# Configure Xdebug
RUN echo 'zend_extension=xdebug' >> /usr/local/etc/php/conf.d/99-xdebug.ini
RUN echo 'xdebug.mode=coverage' >> /usr/local/etc/php/conf.d/99-xdebug.ini

# Install required php extensions
RUN docker-php-ext-install pgsql

RUN composer update