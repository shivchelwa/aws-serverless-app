#
# Dockerfile for project: Coverage.ear
#

FROM shivchelwa/be-enterprise-base:ubuntu-5.5.0-v01
MAINTAINER POC poc@tibco.com

ARG BE_APP_NAME
ARG BE_APP_VERSION
ARG TARGET_DIR

LABEL BE_APP_NAME=$BE_APP_NAME BE_APP_VERSION=$BE_APP_VERSION

ADD . /opt/tibco/be/application

RUN mkdir -p /opt/tibco/be/application/ear
ADD Coverage.ear /opt/tibco/be/application/ear
RUN rm /opt/tibco/be/application/Coverage.ear

ENV CDD_FILE /opt/tibco/be/application/coverage.cdd
ENV EAR_FILE /opt/tibco/be/application/ear/Coverage.ear

#Application's environment variables
ENV Deployment Coverage
ENV HTTP_PORT 8890
ENV Domain domain
ENV MessageEncoding ISO8859-1
ENV CACHE_URL https://es0r4xjoeb.execute-api.us-west-2.amazonaws.com/Prod/coveragedata/
ENV KAFKA_URL ab4f847f5112c11e98b64028047d0b43-975457141.us-west-2.elb.amazonaws.com:9094

#Exposing ports
EXPOSE 8890 
