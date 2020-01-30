FROM postgres:11.6

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python2.7 \
      "postgresql-contrib-$PG_MAJOR" \
      "postgresql-plpython-$PG_MAJOR" \
      "python3-pip"

RUN apt-get install -y --no-install-recommends \
    "postgresql-server-dev-$PG_MAJOR" \
    gcc \
    python3-dev \
    libyaml-dev

RUN apt-get clean \
 && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

RUN pip3 install -U pip setuptools psycopg2-binary
RUN pip3 install yandex-pgmigrate

RUN mkdir /db
COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d/
COPY migrations /db/migrations/
COPY migrations.yml /db/
WORKDIR /db
