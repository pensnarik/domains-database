FROM python:3

ADD datatrace /datatrace
ADD bin /bin
COPY setup.py datatrace.target datatrace@.service datatrace-dispatcher.service /

RUN ls /datatrace/

RUN cd / && python3 setup.py sdist
RUN ls /dist/datatrace*.tar.gz | xargs -n 1 pip install -U

CMD ["python", "/usr/local/bin/datatrace"]