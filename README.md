[![Build Status](https://travis-ci.org/pensnarik/domains-database.svg?branch=master)](https://travis-ci.org/pensnarik/domains-database)

# Datatrace Crawler

Datatrace is a project aimed to collect and keep up to date the list of all active Internet domains.
In addition, tool gathers some extra information about website background: web site encoding, page
size, scripts used on the web site's main page and so forth. The tools is written in Python3 and
uses [PostgreSQL](https://www.postgresql.org/) database as a storage engine. Currently there are
about 3.5 million domains in the database.

# Usage

## Running in Docker

To run the whole application in Docker environment use provided `docker-compose.yml` file:

```bash
docker-compose up
```

To run the crawler in debug mode for a concrete domain use the following command:
```bash
docker-compose run datatrace-app datatrace --domain "kernel.org"
```

## Create a package

```bash
python3 setup.py sdist
```

## Install

```bash
sudo python3 pip install datatrace-<version>.tar.gz
sudo systemctl daemon-reload
```

## Commands

### Version

```bash
$ datatrace --version
Datatrace Crawler, version 126
```

### Debug mode

```bash
$ datatrace --domain example.com

2017-12-26 17:24:40,058 - INFO - Datatrace Crawler, version 126
2017-12-26 17:24:40,207 - INFO - Loaded 71 expressions
2017-12-26 17:24:40,222 - INFO - Loaded meta expressions: {...}
2017-12-26 17:24:40,222 - INFO - Runnig in DEBUG mode for domain gitlab.com
2017-12-26 17:24:40,223 - WARNING - Processing site gitlab.com...
2017-12-26 17:24:40,288 - INFO - IPs: ['52.167.219.168']
2017-12-26 17:24:42,042 - INFO - Charset detected from buffer using <meta> tag
2017-12-26 17:24:42,043 - INFO - Detected charset as utf-8
2017-12-26 17:24:42,144 - INFO - System tags: [46, 58]
2017-12-26 17:24:42,144 - INFO - Processing meta tags for system tag 53
2017-12-26 17:24:42,145 - INFO - Meta tags: {}
2017-12-26 17:24:42,151 - INFO - Phones: []
2017-12-26 17:24:42,176 - INFO - Emails: []
2017-12-26 17:24:42,178 - INFO - Found 7 unique domains on page
2017-12-26 17:24:42,179 - INFO - Charset: utf-8
2017-12-26 17:24:42,179 - INFO - Title: The leading product for integrated software development - GitLab | GitLab
2017-12-26 17:24:42,179 - INFO - Server: nginx
2017-12-26 17:24:42,179 - INFO - Result status is "ok"
```

When using this mode no sessions in database will be created and no information will be saved in the
database.

### Logging expressions search

Use flag `--log-expressions`.

# Contributing

To understand what technologies are used on a website, tool uses [regular expression database](./db/migrations/V004__config_expression.sql). In order to add a new one you can make a PR. You can also refer the
"Issues" and contribute by writing a few lines of code.
