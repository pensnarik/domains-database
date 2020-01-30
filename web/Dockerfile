FROM tiangolo/uwsgi-nginx-flask:python3.7

RUN pip3 install psycopg2-binary requests pytz

COPY ./datatrace_web /app/datatrace_web
COPY datatrace_web.config /usr/local/etc/datatrace_web.config
#COPY prestart.sh /app/prestart.sh
ENV UWSGI_INI /app/datatrace_web/uwsgi.ini
ENV STATIC_PATH /app/datatrace_web/static
