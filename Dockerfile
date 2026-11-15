FROM debian:13 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
	php8.4-cli \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY . /src/

RUN test -f adminer/static/jush/modules/jush-sql.js \
&& test -f conf/JsShrink/jsShrink.php \
&& test -f conf/PhpShrink/phpShrink.php \
|| (echo "Submodules are missing, run: git submodule update --init --recursive" >&2 && exit 1)

RUN php compile.php && mv adminer-*.php adminer.php

RUN php compile.php drivers


FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
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

COPY --from=builder /src/adminer.php /var/www/html/adminer.php

COPY --from=builder /src/plugins/login-sqlite-passwordless.php /var/www/html/adminer-plugins/

COPY --from=builder /src/drivers/redis.php /var/www/html/adminer-plugins/

EXPOSE 8080

CMD [ "php", "-S", "0.0.0.0:8080", "/var/www/html/adminer.php" ]
