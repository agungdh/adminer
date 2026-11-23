ARG UBUNTU_RELEASE=26.04
ARG CHISEL_VERSION=v1.5.1
ARG PHP_VERSION=8.6

FROM ubuntu:${UBUNTU_RELEASE} AS builder

ARG UBUNTU_RELEASE CHISEL_VERSION PHP_VERSION TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	lsb-release \
&& curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
&& dpkg -i /tmp/debsuryorg-archive-keyring.deb \
&& echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
&& rm -f /tmp/debsuryorg-archive-keyring.deb \
&& rm -rf /var/lib/apt/lists/*

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
	php${PHP_VERSION}-cli \
	php${PHP_VERSION}-mysql \
	php${PHP_VERSION}-pgsql \
	php${PHP_VERSION}-sqlite3 \
	sqlite3 \
	mariadb-client \
	postgresql-client \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY . /src/

RUN test -f adminer/static/jush/modules/jush-sql.js \
&& test -f conf/JsShrink/jsShrink.php \
&& test -f conf/PhpShrink/phpShrink.php \
|| (echo "Submodules are missing, run: git submodule update --init --recursive" >&2 && exit 1)

RUN php compile.php && mv adminer-*.php adminer.php

RUN php compile.php drivers

# The final image is a chiseled Ubuntu root filesystem, so install the runtime
# packages here and copy just their files, not apt and the package database.
ADD "https://github.com/canonical/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_${TARGETARCH}.tar.gz" /tmp/chisel.tar.gz

RUN tar -xzf /tmp/chisel.tar.gz -C /usr/bin chisel \
&& mkdir -p /rootfs \
&& chisel cut --release "ubuntu-${UBUNTU_RELEASE}" --root /rootfs \
	base-files_base \
	base-files_release-info \
	base-files_chisel \
	base-passwd_data \
	ca-certificates_data \
	libc6_libs \
	libc6_gconv \
	media-types_data \
	openssl_config \
	tzdata_zoneinfo

RUN cp -a /usr/lib/php /rootfs/usr/lib/ \
&& cp -a /etc/php /rootfs/etc/ \
&& cp -a /usr/bin/php${PHP_VERSION} /rootfs/usr/bin/ \
&& ln -s php${PHP_VERSION} /rootfs/usr/bin/php

RUN install -d -m 1733 /rootfs/var/lib/php/sessions \
&& echo "upload_max_filesize = 128M" >> /rootfs/etc/php/${PHP_VERSION}/cli/conf.d/zz-adminer.ini \
&& echo "post_max_size = 128M" >> /rootfs/etc/php/${PHP_VERSION}/cli/conf.d/zz-adminer.ini \
&& echo "memory_limit = 1G" >> /rootfs/etc/php/${PHP_VERSION}/cli/conf.d/zz-adminer.ini \
&& echo "max_execution_time = 600" >> /rootfs/etc/php/${PHP_VERSION}/cli/conf.d/zz-adminer.ini \
&& echo "max_input_vars = 5000" >> /rootfs/etc/php/${PHP_VERSION}/cli/conf.d/zz-adminer.ini

RUN for bin in \
	mariadb mariadb-admin mariadb-binlog mariadb-check mariadb-dump \
	mariadb-import mariadb-show my_print_defaults mysql mysqladmin mysqldump; do \
	if [ -e "/usr/bin/$bin" ]; then cp -a "/usr/bin/$bin" /rootfs/usr/bin/; fi; \
done \
&& for bin in \
	clusterdb createdb createuser dropdb dropuser pg_dump pg_dumpall \
	pg_isready pg_restore psql reindexdb vacuumdb; do \
	for file in /usr/lib/postgresql/*/bin/$bin; do \
		if [ -x "$file" ]; then cp -a "$file" /rootfs/usr/bin/; fi; \
	done; \
done \
&& if [ -e /usr/bin/sqlite3 ]; then cp -a /usr/bin/sqlite3 /rootfs/usr/bin/; fi

RUN for dir in /usr/lib/*-linux-gnu*/libmariadb3; do \
	if [ -d "$dir" ]; then cp -a --parents "$dir" /rootfs/; fi; \
done

# Copy the shared libraries required by PHP, its modules and the clients.
# ldd resolves the transitive closure, including libraries loaded at runtime
# by the extensions, so the chiseled image does not need apt to pull them in.
RUN set -euo pipefail; \
	{ find /rootfs/usr/bin /rootfs/usr/lib/php -type f; find /rootfs/usr/lib/*-linux-gnu*/libmariadb3 -type f 2>/dev/null || true; } > /tmp/elf-files; \
	: > /tmp/ldd.txt; \
	while IFS= read -r file; do \
		ldd "$file" >> /tmp/ldd.txt 2>/dev/null || true; \
	done < /tmp/elf-files; \
	if grep -q 'not found' /tmp/ldd.txt; then \
		echo "Unresolved shared libraries:" >&2; \
		grep 'not found' /tmp/ldd.txt >&2; \
		exit 1; \
	fi; \
	awk '/=> \// { print $3 } /^[[:space:]]*\// { print $1 }' /tmp/ldd.txt | sort -u > /tmp/elf-libs; \
	while IFS= read -r lib; do \
		mkdir -p "/rootfs$(dirname "$lib")"; \
		cp -a "$lib" "/rootfs$lib"; \
		real=$(readlink -f "$lib"); \
		if [ "$real" != "$lib" ]; then \
			mkdir -p "/rootfs$(dirname "$real")"; \
			cp -a "$real" "/rootfs$real"; \
		fi; \
	done < /tmp/elf-libs; \
	for file in /etc/ld.so.cache /etc/nsswitch.conf /etc/services; do \
		if [ -e "$file" ]; then cp -a "$file" /rootfs/etc/; fi; \
	done

RUN chroot /rootfs /usr/bin/php -v \
&& chroot /rootfs /usr/bin/php -r 'exit(extension_loaded("mysqli") && extension_loaded("pgsql") && extension_loaded("pdo_sqlite") ? 0 : 1);'


FROM scratch

COPY --from=builder /rootfs /

STOPSIGNAL SIGINT

WORKDIR /var/www/html

COPY --from=builder /src/adminer.php /var/www/html/adminer.php

COPY --from=builder /src/plugins/login-sqlite-passwordless.php /var/www/html/adminer-plugins/

COPY --from=builder /src/plugins/login-redis-passwordless.php /var/www/html/adminer-plugins/

COPY --from=builder /src/drivers/redis.php /var/www/html/adminer-plugins/

EXPOSE 8080

CMD [ "/usr/bin/php", "-S", "0.0.0.0:8080", "/var/www/html/adminer.php" ]
