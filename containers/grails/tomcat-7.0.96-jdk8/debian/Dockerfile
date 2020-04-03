FROM tomcat:7.0.96-jdk8-openjdk

MAINTAINER Morpheus <docker@morpheusdata.com>

ADD grails_startup.sh /grails_startup.sh
ADD startup.txt /startup.txt

RUN chmod 755 /*.sh & \
	mkdir -p /morpheus/data & \
	mkdir -p /morpheus/config & \
	mkdir -p /morpheus/logs

EXPOSE 8080

CMD ["/grails_startup.sh"]
