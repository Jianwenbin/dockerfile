FROM php:5.6-apache 

RUN apt-get update && \
  apt-get install -y --no-install-recommends libfreetype6-dev libjpeg62-turbo-dev libpng-dev && \
  rm -r /var/lib/apt/lists/* && \
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/  

RUN docker-php-ext-install gd mysqli pdo pdo_mysql zip

RUN a2enmod rewrite

RUN usermod -u 1000 www-data

