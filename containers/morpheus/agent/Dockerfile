FROM amazoncorretto:17

MAINTAINER Morpheus <docker@morpheusdata.com>

# Exposed ENV
ENV JVM_MIN_MEM 32m
ENV JVM_MAX_MEM 128m
# ENV AGENT_CONFIG - optional to pass config

WORKDIR /var/opt/morpheus
COPY agent.jar agent.jar
COPY morpheus-entrypoint.sh entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD ["java"]
