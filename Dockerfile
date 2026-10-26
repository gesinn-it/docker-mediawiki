###################################################
# gesinn-it/mediawiki:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache
#
# MEDIAWIKI_VERSION: MediaWiki Version
# PHP_VERSION: PHP Version
# XDEBUG_VERSION: Xdebug Version
# COMPOSER_VERSION: Composer Version
# MEDIAWIKI_TOOLS_VERSION: version of gesinn-it-pub/docker-mediawiki-tools
#
# The pinned versions are kept up to date by Renovate (see renovate.json).
# The CI workflow reads COMPOSER_VERSION and MEDIAWIKI_TOOLS_VERSION from here for the image labels.
###################################################
ARG MEDIAWIKI_VERSION=1.46.2
ARG PHP_VERSION=8.4
ARG COMPOSER_VERSION=2.10.3
# optional, "@sha256:...": pins the gesinn/mediawiki-base image to the digest recorded in the labels
ARG MEDIAWIKI_BASE_DIGEST=

FROM composer:${COMPOSER_VERSION} AS composer

FROM gesinn/mediawiki-base:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache${MEDIAWIKI_BASE_DIGEST} AS mediawiki

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

# Composer does not block on security advisories: a finding in a dev dependency (which this image
# does not install) must not stop the build. The audit gate below decides instead, see audit-gate.php.
RUN composer config --global policy.advisories.block false && \
    composer update \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --no-scripts

# Fail on high/critical advisories in the installed (non-dev) packages unless accepted in audit-triage.json
RUN --mount=type=bind,source=audit-gate.php,target=/tmp/audit-gate.php \
    --mount=type=bind,source=audit-triage.json,target=/tmp/audit-triage.json \
    php /tmp/audit-gate.php /tmp/audit-triage.json strict --no-dev

###################################################
# gesinn-it/mediawiki-ci:${MEDIAWIKI_VERSION}-php${PHP_VERSION}-apache
###################################################
FROM mediawiki AS mediawiki-ci

ARG XDEBUG_VERSION=3.3.2
ARG MEDIAWIKI_TOOLS_VERSION=5.3.0

### add build tools and patches folder
RUN curl -LJ https://github.com/gesinn-it-pub/docker-mediawiki-tools/tarball/${MEDIAWIKI_TOOLS_VERSION} \
	| tar xzC / --strip-components 1

RUN chmod +x /build-tools/* /tools/*
ENV PATH="/tools:/build-tools:${PATH}"

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Install XDebug
RUN pecl install "https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz" \
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

# The dev tools are only used by this CI image: advisories in them are reported, but do not fail the build
RUN composer update \
    --prefer-dist \
    --no-interaction \
    --no-progress

RUN --mount=type=bind,source=audit-gate.php,target=/tmp/audit-gate.php \
    --mount=type=bind,source=audit-triage.json,target=/tmp/audit-triage.json \
    php /tmp/audit-gate.php /tmp/audit-triage.json warn
