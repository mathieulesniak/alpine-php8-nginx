FROM alpine:3.13
LABEL Maintainer="Mathieu LESNIAK <mathieu@lesniak.fr>"\
    Description="Lightweight container with Nginx 1.18 & PHP-FPM 8 based on Alpine Linux."

RUN apk update && \
    apk add bash less geoip nginx nginx-mod-http-headers-more nginx-mod-http-geoip nginx-mod-stream nginx-mod-stream-geoip ca-certificates git tzdata zip \
    libmcrypt-dev zlib-dev gmp-dev freetype-dev libjpeg-turbo-dev libpng-dev curl \
    php8-common php8-fpm php8-json php8-zlib php8-xml php-xmlwriter php8-pdo php8-phar php8-openssl php8-fileinfo php8-pecl-imagick \
    php8-pdo_mysql php8-mysqli php8-session \
    php8-gd php8-iconv php8-pecl-mcrypt php8-gmp php8-zip \
    php8-curl php8-opcache php8-ctype php8-pecl-apcu php8-pecl-memcached \
    php8-intl php8-bcmath php8-dom php8-mbstring php8-simplexml php8-soap php8-tokenizer php8-xmlreader php8-xmlwriter php8-pcntl && \
    apk add -u musl && \
    apk add msmtp && \
    rm -rf /var/cache/apk/*

RUN { \
    echo '[mail function]'; \
    echo 'sendmail_path = "/usr/bin/msmtp -t"'; \
    } > /etc/php8/conf.d/msmtp.ini

# opcode recommended settings
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=64'; \
    echo 'opcache.max_accelerated_files=25000'; \
    echo 'opcache.revalidate_path=0'; \
    echo 'opcache.enable_file_override=1'; \
    echo 'opcache.max_file_size=0'; \
    echo 'opcache.max_wasted_percentage=5;' \
    echo 'opcache.revalidate_freq=120'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=0'; \ 
    echo 'opcache.jit_buffer_size=64M'; \
    echo 'opcache.jit=tracing';\ 
    } > /etc/php8/conf.d/opcache-recommended.ini

# limits settings
RUN { \
    echo 'memory_limit=256M'; \
    echo 'upload_max_filesize=128M'; \
    echo 'max_input_vars=5000'; \
    echo "date.timezone='Europe/Paris'"; \
    } > /etc/php8/conf.d/limits.ini

RUN sed -i "s/nginx:x:100:101:nginx:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:nginx:\/usr:\/bin\/bash/g" /etc/passwd && \
    sed -i "s/nginx:x:100:101:nginx:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:nginx:\/usr:\/bin\/bash/g" /etc/passwd- && \
    rm /etc/nginx/conf.d/default.conf && \
    ln -s /sbin/php-fpm8 /sbin/php-fpm && \
    ln -s /usr/bin/php8 /usr/bin/php

# Composer
RUN cd /tmp/ && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update

ADD php-fpm.conf /etc/php8/
ADD nginx-site.conf /etc/nginx/nginx.conf
ADD entrypoint.sh /etc/entrypoint.sh
ADD ownership.sh /
RUN mkdir -p /var/www/public
COPY --chown=nobody src/ /var/www/public/


WORKDIR /var/www/
EXPOSE 80

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

ENTRYPOINT ["sh", "/etc/entrypoint.sh"]

