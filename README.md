# docker-mediawiki
![CI](https://github.com/gesinn-it/docker-mediawiki/actions/workflows/main.yml/badge.svg)

Dockerized MediaWiki build on top of docker-mediawiki-base images in the style of the official MediaWiki Docker images with preinstalled Composer, MediaWiki and enabled Xdebug. This image is intended to be used during development, testing and CI workflows.

- `$wgServer = http://localhost:8080`
- Wiki Admin: WikiSysop
- Password: wiki4everyone

## Important directories
- `/etc/apache`
- `/usr/local/etc/php/`
