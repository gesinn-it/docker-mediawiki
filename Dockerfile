###################################################
# gesinn-it/docker-mediawiki:mw-%%BASE_IMAGE_TAG%%
#
# MEDIAWIKI_VERSION: MediaWiki Version
# PHP_VERSION: PHP Version
###################################################
ARG MEDIAWIKI_VERSION
ARG PHP_VERSION

FROM gesinn/docker-mediawiki-base-apache:${MEDIAWIKI_VERSION}-php${PHP_VERSION}

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

# Install XDebug
# ToDo: remove/adapt version pinning for newer PHP versions
RUN pecl install xdebug-3.1.6

# Configure Xdebug
RUN echo 'zend_extension=xdebug' >> /usr/local/etc/php/conf.d/99-xdebug.ini
RUN echo 'xdebug.mode=coverage' >> /usr/local/etc/php/conf.d/99-xdebug.ini

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN ls -la /

# Install Composer packages
RUN composer update
