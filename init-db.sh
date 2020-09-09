#!/usr/bin/env bash

docker-compose stop datatrace-db
docker-compose rm -f datatrace-db
docker-compose up datatrace-db
