FROM alpine:3.11

# Install packages  
RUN apk add --update --no-cache python3   
RUN pip3 install --upgrade pip setuptools

# Install other packages
RUN apk --no-cache add php php-fpm php-opcache php-openssl php-curl nginx supervisor curl
RUN apk add openrc --no-cache

# Set up Python
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python  
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools 
RUN pip3 install --no-cache-dir testinfra

# Set up PHP
RUN { [ ! -e /usr/bin/php ] && ln -s /usr/bin/php7 /usr/bin/php; } || true  

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf  

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set up document root 
RUN mkdir -p /var/www/html
RUN chown -R nobody.nobody /var/www/html 

USER nobody
WORKDIR /var/www/html

# Add application 
COPY --chown=nobody src/ /var/www/html/

# Run tests
RUN pytest /etc/nginx/test/test.py

EXPOSE 8080  
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]  
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
