FROM python:3
COPY datatrace-*.tar.gz /
COPY datatrace.config /etc/
RUN ls /datatrace*.tar.gz | xargs -n 1 pip install -U

CMD ["python", "/usr/local/bin/datatrace"]