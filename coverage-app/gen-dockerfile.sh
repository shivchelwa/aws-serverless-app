#!/bin/bash

${BE_HOME}/docker/bin/be-docker-gen --propFile ${BE_HOME}/docker/bin/be-docker-gen.tra -t . -i shivchelwa/be-enterprise-base:ubuntu-5.5.0-v01 -m POC -e poc@tibco.com -o true
