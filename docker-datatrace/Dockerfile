FROM python:3
ENV VERSION=0.6.15
COPY datatrace-${VERSION}.tar.gz /
COPY datatrace.config /etc/
RUN pip install -U /datatrace-${VERSION}.tar.gz

CMD ["python", "/usr/local/bin/datatrace"]