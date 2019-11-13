FROM php:7.2-fpm

LABEL maintainer="hello@withknown.com"

RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-client \
 && savedAptMark="$(apt-mark showmanual)" \
 && apt-get install -y --no-install-recommends \
      libfreetype6-dev \
      libicu-dev \
      libjpeg-dev \
      libmcrypt-dev \
      libmcrypt-dev \
      libpng-dev \
      libxml2-dev \
 && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
 && docker-php-ext-install exif gd intl opcache pdo_mysql zip json xmlrpc \
 && pecl install mcrypt-1.0.3 \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
 && apt-mark auto '.*' > /dev/null \
 && apt-mark manual $savedAptMark \
 && ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual \
 && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
 && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
  echo 'opcache.memory_consumption=128'; \
  echo 'opcache.interned_strings_buffer=8'; \
  echo 'opcache.max_accelerated_files=4000'; \
  echo 'opcache.revalidate_freq=60'; \
  echo 'opcache.fast_shutdown=1'; \
  echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PECL extensions
RUN pecl install APCu-5.1.18 \
 && docker-php-ext-enable apcu mcrypt

ENV KNOWN_VERSION 1.0.0
VOLUME /var/www/html

RUN fetchDeps=" \
    gnupg \
    dirmngr \
  " \
 && apt-get update \
 && apt-get install -y --no-install-recommends $fetchDeps \
 && curl -o known.tgz -fSL https://withknown.marcus-povey.co.uk/known-${KNOWN_VERSION}.tgz \
 && curl -o known.tgz.sha256 -fSL https://withknown.marcus-povey.co.uk/known-${KNOWN_VERSION}.tgz.sha256 \
 && curl -o known.tgz.sha256.gpg -fSL https://withknown.marcus-povey.co.uk/known-${KNOWN_VERSION}.tgz.sha256.gpg \
 && export GNUPGHOME="$(mktemp -d)" \
#gpg key from marcus@marcus-povey.co.uk
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "E3F1C15C43A1E393A4B88C6E20FD53C2397813CA" \
 && gpg --batch --verify known.tgz.sha256.gpg known.tgz.sha256 \
 # && sha256sum hmm the sha256 file is binary and too large
 && mkdir /usr/src/known \
 && tar -xf known.tgz -C /usr/src/known \
 && rm -r "$GNUPGHOME" known.tgz* \
 && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps \
 && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
