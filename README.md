> **Modified version.** This is a personal fork of [Adminer](https://www.adminer.org/), kept in sync with the latest upstream release. Release tags carry an `-agungdh.N` suffix so they never collide with upstream's. Changes against upstream:
>
> - **Passwordless SQLite login** — `plugins/login-sqlite-passwordless.php` lets you log in to SQLite without credentials; other drivers are unaffected.
> - **Passwordless Redis login** — `plugins/login-redis-passwordless.php` does the same for Redis, so a server without `requirepass` needs no password; a server requiring one still reports its own error.
> - **Custom Docker image** — `Dockerfile` on a slim Debian base with PHP CLI and only MariaDB, PostgreSQL, SQLite and Redis. Compiled via `compile.php`, served on port 8080.
> - **Redis driver** — bundled by `php compile.php drivers`.
> - **Multi-arch Docker publish** — GitHub Actions builds `linux/amd64` + `linux/arm64` on release, pushes to `ghcr.io/agungdh/adminer`. Branch pushes only build and smoke test.
>
> Everything below is the original upstream README.

# Adminer
**Adminer** is a full-featured database management tool written in PHP. It consists of a single file ready to deploy to the target server.
**Adminer Editor** offers data manipulation for end-users.

[Official Website](https://www.adminer.org/)

## Features
- **Supports:** MySQL, MariaDB, PostgreSQL, CockroachDB, SQLite, MS SQL, Oracle
- **Plugins for:** Elasticsearch, OpenSearch, SimpleDB, MongoDB, Redis, Firebird, ClickHouse, IGDB, IMAP
- **Requirements:** PHP 5.4+ (compiled file), PHP 7.4+ (source codes)

## Screenshot
![Table structure](https://www.adminer.org/static/screenshots/table.webp)

## Installation
If downloaded from Git then run: `git submodule update --init` (or `composer install`)

- `adminer/index.php` - Run development version of Adminer
- `editor/index.php` - Run development version of Adminer Editor, needs `adminer/` next to it
- `editor/example.php` - Example customization
- `compile.php` - Create a single file version
- `lang.php` - Update translations
- `tests/*.spec.js` - Playwright end-to-end tests

## Plugins
There are several plugins distributed with Adminer, as well as many user-contributed plugins listed on the [Adminer Plugins page](https://www.adminer.org/plugins/).
