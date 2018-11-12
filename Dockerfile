FROM node:10-alpine AS node

FROM php:7-fpm-alpine

ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_PATH=/usr/local/bin COMPOSER_COMMAND=composer
ENV SYMFONY_ENV=dev

VOLUME /app
WORKDIR /app

RUN set -xe \
 && apk add --no-cache git openssh-client coreutils freetype-dev libjpeg-turbo-dev libltdl libpng-dev icu icu-libs icu-dev unzip \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && docker-php-ext-install -j$(nproc) iconv mbstring intl gd zip \
 && apk add --no-cache --virtual build-deps g++ autoconf make python linux-headers \
 && docker-php-source extract \
 && git clone git://github.com/xdebug/xdebug.git \
 && cd xdebug \
 && ./rebuild.sh \
 && cd .. \
 && rm -Rf ./xdebug \
 && pecl install apcu \
 && docker-php-ext-enable xdebug opcache apcu \
 && docker-php-source delete \
 && mkdir -p /var/lib/php/sessions \
 && chown -Rf www-data:www-data /var/lib/php/sessions \
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=${COMPOSER_PATH} --filename=${COMPOSER_COMMAND}

USER www-data
RUN $COMPOSER_COMMAND global require hirak/prestissimo:^0.3 \
 && $COMPOSER_COMMAND global require roave/security-advisories:dev-master

USER root
COPY ./docker/php-fpm/php-settings.conf /usr/local/etc/php-fpm.d/


COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=node /usr/local/share/systemtap/tapset/node.stp /usr/local/share/systemtap/tapset/node.stp
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

USER www-data

