FROM amazoncorretto:17

MAINTAINER Morpheus <docker@morpheusdata.com>

# Exposed ENV
ENV JVM_MIN_MEM 64m
ENV JVM_MAX_MEM 64m

RUN mkdir -p /morpheus/data
RUN mkdir -p /morpheus/config
RUN mkdir -p /morpheus/logs

VOLUME /morpheus/data
VOLUME /morpheus/config
VOLUME /morpheus/logs

ADD morpheus-entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ADD morpheus-welcome-all.jar /app.jar

ENTRYPOINT ["/entrypoint.sh"]

CMD ["java"]

