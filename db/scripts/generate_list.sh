#!/bin/sh

cat "$1" | awk --field-separator=';' '{print "select add_domain(\x27"tolower($1)"\x27);"}' > "$1.sql"
