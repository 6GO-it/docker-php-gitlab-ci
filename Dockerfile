# Consider switching to :alpine in the future
FROM php:7.3-cli-stretch

LABEL maintainer="open-source@6go.it" \
    vendor=6go.it \
    version=1.0.6

# Set up some basic global environment variables
ARG NODE_ENV
ENV NODE_ENV $NODE_ENV
ENV DEBIAN_FRONTEND noninteractive
ENV COMPOSER_ALLOW_SUPERUSER=1

# Let's start by adding few repository
# necessary for any general PHP application tested with Gitlab
# For instance sshpass is useful if you want to autodeploy!
RUN apt-get update -y -qq \
    && apt-get install -y -qq apt-utils apt-transport-https gnupg

# Add repository to /etc/apt/source.list
RUN echo "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    # Since node will update the package we won't need to do that later
    && curl -sL https://deb.nodesource.com/setup_12.x | bash -

# Install common libraries and commands
RUN apt-get install -y -qq build-essential git sshpass iputils-ping \
    libzip-dev zlib1g-dev libcurl4-gnutls-dev libicu-dev libmcrypt-dev \
    libvpx-dev libjpeg-dev libpng-dev libxpm-dev zlib1g-dev \
    libfreetype6-dev libxml2-dev libexpat1-dev libbz2-dev libgmp3-dev \
    libldap2-dev unixodbc-dev libpq-dev libsqlite3-dev libaspell-dev \
    libsnmp-dev libpcre3-dev libtidy-dev libmagickwand-dev\
    jpegoptim optipng pngquant gifsicle ffmpeg nodejs yarn

# Compile PHP, include these extensions.
# Symbolic link necessary for php extensions
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/

# Since PHP 7.2 mcrypt is not enabled by default so we need to include it manually
# Please see https://stackoverflow.com/a/47673183/1202367
# Install also xDebug latest stable, imagick and MongoDB
RUN yes | pecl install -s mcrypt-1.0.2 xdebug-2.7.2 imagick mongodb \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

# Install other PECL/PEAR extensions
RUN pear install PHP_CodeSniffer

# Install PHP Extensions
RUN docker-php-source extract \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/freetype2 --with-png-dir=/usr/include --with-jpeg-dir=/usr/include \
    && docker-php-ext-install -j$(nproc) bcmath bz2 exif gmp gd iconv intl mysqli opcache pcntl pdo_mysql pdo_pgsql pgsql zip \
    && docker-php-ext-enable xdebug opcache gd mcrypt imagick \
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
    && apt-get autoremove -y autoconf automake build-essential \
    cmake mercurial texinfo \
    && apt-get clean \
    && apt-get autoclean \
    && echo -n > /var/lib/apt/extended_states \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/man/?? \
    && rm -rf /usr/share/man/??_*
