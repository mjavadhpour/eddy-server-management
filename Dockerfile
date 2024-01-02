#syntax=docker/dockerfile:1.4

# Versions
FROM docker.io/php:8.2-fpm-alpine AS php_upstream
FROM docker.io/mlocati/php-extension-installer:2 AS php_extension_installer_upstream
FROM docker.io/composer/composer:2-bin AS composer_upstream
FROM docker.io/node:18.15.0-alpine AS node_pnpm
RUN npm install -g pnpm@8.5.1
ENV PATH="/root/.local/share/pnpm:$PATH"

# Base PHP image
FROM php_upstream AS php_base

WORKDIR /srv/app

# persistent / runtime deps
# hadolint ignore=DL3018
RUN apk add --no-cache \
		acl \
		fcgi \
		file \
		gettext \
		git \
	;

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
COPY --from=php_extension_installer_upstream --link /usr/bin/install-php-extensions /usr/local/bin/

RUN set -eux; \
    install-php-extensions \
		apcu \
		intl \
		opcache \
		zip \
		bcmath \
		pcntl \
		pdo_mysql \
		redis \
		xdebug \
    ;

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"
COPY --from=composer_upstream --link /composer /usr/bin/composer
COPY --from=node_pnpm /usr/local/lib /usr/local/lib
COPY --from=node_pnpm /usr/local/bin /usr/local/bin
