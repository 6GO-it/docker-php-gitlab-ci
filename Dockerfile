FROM php:7.2-cli

LABEL maintainer="open-source@6go.it" \
    vendor=6go.it \
    version=1.0.0

# Set up some basic global environment variables
ARG NODE_ENV
ENV NODE_ENV $NODE_ENV
ENV DEBIAN_FRONTEND noninteractive

# Let's start by adding few repository
# necessary for any general PHP application tested with Gitlab
# For instance sshpass is useful if you want to autodeploy!
RUN apt-get update -y -qq \
    && apt-get install -y -qq apt-utils apt-transport-https gnupg

# Add repository to /etc/apt/source.list
RUN echo "deb http://ftp.uk.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    # Since node will update the package we won't need to do that later
    && curl -sL https://deb.nodesource.com/setup_10.x | bash -

# Install necessari libs and commands
RUN apt-get install -y -qq apt-utils apt-transport-https \
    build-essential git sshpass iputils-ping nodejs yarn \
    libcurl4-gnutls-dev libicu-dev libmcrypt-dev \
    libvpx-dev libjpeg-dev libpng-dev libxpm-dev zlib1g-dev \
    libfreetype6-dev libxml2-dev libexpat1-dev libbz2-dev libgmp3-dev \
    libldap2-dev unixodbc-dev libpq-dev libsqlite3-dev libaspell-dev \
    libsnmp-dev libpcre3-dev libtidy-dev \
    jpegoptim optipng pngquant gifsicle ffmpeg

# Compile PHP, include these extensions.
# Symbolic link necessary for php extensions
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/

# Since PHP 7.2 mcrypt is not enabled by default so we need to include it manually
# Please see https://stackoverflow.com/a/47673183/1202367
RUN yes | pecl install -s mcrypt-1.0.1

# Configure xDebug
RUN yes | pecl install -s xdebug-2.6.1 \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

# Install PHP Extensions
RUN docker-php-source extract \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/freetype2 --with-png-dir=/usr/include --with-jpeg-dir=/usr/include \
    && docker-php-ext-install -j$(nproc) iconv bcmath bz2 exif gmp gd intl mysqli opcache pdo_mysql pdo_pgsql pgsql zip \
    && docker-php-ext-enable xdebug opcache gd mcrypt \
    && docker-php-source delete \
    # Sanity check
    && php -v \
    && php -m

# Install Composer and project dependencies.
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    # Sanity check
    && composer -V

# Get nodejs and npm in order to be able to test stuff on dusk or feature tests
RUN npm install -g svgo

# Clean up all the mess done by installing stuff
RUN apt-get remove --purge -y software-properties-common \
    && apt-get autoremove -y \
    autoconf automake \
    build-essential \
    cmake mercurial \
    texinfo \
    && apt-get clean \
    && apt-get autoclean \
    && echo -n > /var/lib/apt/extended_states \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/man/?? \
    && rm -rf /usr/share/man/??_*