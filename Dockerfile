FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
	ca-certificates \
	php8.4-cli \
	php8.4-mysql \
	php8.4-pgsql \
	php8.4-sqlite3 \
	sqlite3 \
	mariadb-client \
	postgresql-client \
&& rm -rf /var/lib/apt/lists/*

RUN echo "upload_max_filesize = 128M" >> /etc/php/8.4/cli/conf.d/zz-adminer.ini \
&& echo "post_max_size = 128M" >> /etc/php/8.4/cli/conf.d/zz-adminer.ini \
&& echo "memory_limit = 1G" >> /etc/php/8.4/cli/conf.d/zz-adminer.ini \
&& echo "max_execution_time = 600" >> /etc/php/8.4/cli/conf.d/zz-adminer.ini \
&& echo "max_input_vars = 5000" >> /etc/php/8.4/cli/conf.d/zz-adminer.ini

STOPSIGNAL SIGINT

WORKDIR /var/www/html

COPY . /var/www/html/

EXPOSE 8080

CMD [ "php", "-S", "0.0.0.0:8080", "-t", "/var/www/html" ]
