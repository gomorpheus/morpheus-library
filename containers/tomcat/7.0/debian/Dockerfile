FROM tomcat:7.0.96-jdk8-openjdk

MAINTAINER Morpheus <docker@morpheusdata.com>

ADD tomcat_startup.sh /tomcat_startup.sh
ADD startup.txt /startup.txt

RUN chmod 755 /*.sh & \
	mkdir -p /morpheus/data & \
	mkdir -p /morpheus/config & \
	mkdir -p /morpheus/logs

EXPOSE 8080

CMD ["/tomcat_startup.sh"]
