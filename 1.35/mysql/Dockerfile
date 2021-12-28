###################################################
# gesinn-it/docker-mediawiki:mw-1.35.5
#
# MEDIAWIKI_VERSION: MediaWiki Version
# COMPOSER_VERSION: Composer Major Version (1 or 2)
###################################################
FROM mediawiki:1.35.5

ARG MYSQL_PORT

# Fix owner
RUN chown -R www-data:www-data .

# Existential tools
RUN apt-get update && \
    apt-get install -y \
        sudo \
        unzip \
        less \
        nano \
        nodejs \
        npm

# Install MySQL client for debugging
# RUN apt-get install -y default-mysql-client

# Test MySQL Connection
# RUN mysql --host 127.0.0.1 --port ${MYSQL_PORT} -uroot -pdatabase -e "SELECT @@VERSION"

# MySQL grant privileges
# RUN mysql --host 127.0.0.1 --port ${MYSQL_PORT} -uroot -pdatabase -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'database'"

# Test PHP and install pdo_mysql
RUN php -m && \
    docker-php-ext-install pdo_mysql && \
    php -m

# Bashrc Alias
RUN echo "alias ll='ls -la'" >> /etc/bash.bashrc && \
    echo "alias ..='cd ..'" >> /etc/bash.bashrc && \
    echo "alias ...='cd ...'" >> /etc/bash.bashrc

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'installer');" && \
    php -r "copy('https://composer.github.io/installer.sig', 'expected');" && \
    echo `cat expected` " installer" | sha384sum -c - && \
    php installer --version=2.1.14 && \
    rm -f installer expected && \
    mv composer.phar /usr/local/bin/composer

# Install XDebug
RUN pecl install xdebug && \
    bash -c "echo 'zend_extension=xdebug' >> /usr/local/etc/php/conf.d/99-xdebug.ini" && \
    bash -c "echo 'xdebug.mode=coverage' >> /usr/local/etc/php/conf.d/99-xdebug.ini" && \
    php -v

# Setup MediaWiki
RUN sudo -u www-data composer update && \
    sudo -u www-data php maintenance/install.php \
        --pass=wiki4everyone \
        --server="http://localhost:8080" \
        --scriptpath="" \
        --dbserver=127.0.0.1:${MYSQL_PORT} \
        --installdbuser=root \
        --installdbpass=database \
        --dbtype=mysql \
        --dbname=wiki \
        --dbuser=wiki \
        --dbpass=wiki \
        wiki WikiSysop

# Enable debug output, enable JS testing
RUN bash -c "echo 'error_reporting(E_ALL| E_STRICT);' >> LocalSettings.php" && \
    bash -c "echo 'ini_set(\"display_errors\", 1);' >> LocalSettings.php" && \
    bash -c 'echo "\$wgShowExceptionDetails = true;" >> LocalSettings.php' && \
    bash -c 'echo "\$wgDevelopmentWarnings = true;" >> LocalSettings.php' && \
    bash -c 'echo "\$wgEnableJavaScriptTest = true;" >> LocalSettings.php' && \
    bash -c 'echo "\$wgDebugToolbar = true;" >> LocalSettings.php' && \
    tail -n6 LocalSettings.php
