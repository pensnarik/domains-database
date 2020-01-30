#!/bin/bash

for ((i=1;i<=199;i++)); do psql -U datatrace -h home.parselab.ru -p 6432 datatrace -c ""; echo $i; done;
