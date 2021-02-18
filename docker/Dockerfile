# This Dockerfile was based off Woh Shon's image:
# https://hub.docker.com/r/wohshon/jmeter

FROM registry.access.redhat.com/ubi8/openjdk-8

# JMeter Version
ARG JMETER_VERSION="5.4.1"

MAINTAINER Koo Kin Wai <kin.wai.koo@gmail.com>

LABEL \
  io.k8s.description="Image for running JMeter test scripts" \
  io.k8s.display-name="JMeter ${JMETER_VERSION}" \
  io.openshift.tags="builder,jmeter"

USER root

# Download and unpack the JMeter tar file
RUN \
  mkdir /tmp/install \
  && \
  cd /tmp/install \
  && \
  curl -o jmeter.tgz https://apachemirror.sg.wuchna.com/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz \
  && \
  tar zxf jmeter.tgz \
  && \
  mv apache-jmeter-${JMETER_VERSION} /opt/jmeter \
  && \
  mkdir /opt/jmeter/testplan \
  && \
  chown -R 185:0 /opt/jmeter \
  && \
  ln -s /opt/jmeter/bin/jmeter /usr/local/bin/ \
  && \
  rm -rf /tmp/install \
  && \
  mkdir /www \
  && \
  chmod 775 /www \
  && \
  chown 185:0 /www

COPY s2i/assemble /usr/local/s2i/assemble
COPY s2i/run /usr/local/s2i/run

RUN \
  chmod 755 /usr/local/s2i/assemble /usr/local/s2i/run \
  && \
  chown 185:0 /usr/local/s2i/assemble /usr/local/s2i/run

USER 185



# not using this to expose a prompt for user to manually run the test plan, e.g: 
# CMD ["jmeter", "-n", "-t", "/tmp/Fuse-TestPlan.jmx", "-l", "/tmp/results/results.jtl", "-e", "-o", "/tmp/db"]
# run this after oc run > jmeter -n -t /opt/apache-jmeter-5.4.1/testplan/testplan.jmx -l /opt/apache-jmeter-5.4.1/results/result.jtl -e -o /opt/apache-jmeter-5.4.1/dashboard/