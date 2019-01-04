#!/usr/bin/env bash

# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# updated to start Kafka so it can be accessed by processes of different region and accounts.

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
REPO=https://github.com/Yolean/kubernetes-kafka.git
REPODIR=kubernetes-kafka

function main {
    array=( $(kubectl get sts/kafka -n kafka | grep kafka) )
    if [ $? -eq 0 ] && [ ${array[2]} -gt 0 ]; then
      echo "Found ${array[2]} kafka instances running already"
      return 1
    fi
    echo "Beginning setup of Kafka for Hyperledger Fabric orderer ..."
    getRepo
    startStorageService
    startZookeeper
    startKafka
#    testKafka
    whatsRunning
    echo "Kafka startup complete"
}

function getRepo {
    echo "Getting repo $REPO at $SDIR"
    cd $HOME
    if [ ! -d $REPODIR ]; then
        # clone repo, if it hasn't already been cloned
        git clone $REPO
        cd $REPODIR
        git checkout tags/v4.3.1
    fi
}

function startStorageService {
    echo "Starting storage service required for Kafka"
    kubectl apply -f $HOME/$REPODIR/configure/aws-storageclass-zookeeper-gp2.yml
    kubectl apply -f $HOME/$REPODIR/configure/aws-storageclass-broker-gp2.yml
}

function startZookeeper {
    echo "Starting Zookeeper service"
    kubectl apply -f $HOME/$REPODIR/00-namespace.yml
    kubectl apply -f $HOME/$REPODIR/zookeeper/10zookeeper-config.yml
    kubectl apply -f $HOME/$REPODIR/zookeeper/20pzoo-service.yml
    kubectl apply -f $HOME/$REPODIR/zookeeper/21zoo-service.yml
    kubectl apply -f $HOME/$REPODIR/zookeeper/30service.yml
    kubectl apply -f $HOME/$REPODIR/zookeeper/50pzoo.yml
    kubectl apply -f $HOME/$REPODIR/zookeeper/51zoo.yml
}

# this process is updated to expose each kafka broker using a separate LoadBalancer,
# and 10broker-config.yml is updated to use external LoadBalancer,
# without these changes, remote publisher/consumer would not work.
function startKafka {
    echo "Starting Kafka service"
    source ${SDIR}/kafka-elb.sh
    createKafkaELBs
    kubectl apply -f $SDIR/10broker-config.yml
    source ${SDIR}/kafka-broker.sh
    startKafkaBrokers
    
    #wait for Kafka to deploy. This could take a couple of minutes
    PODSPENDING=$(kubectl get pods --namespace=kafka | awk '{print $2}' | cut -d '/' -f1 | grep 0 | wc -l | awk '{print $1}')
    while [ "${PODSPENDING}" != "0" ]; do
        echo "Waiting on Kafka to deploy. Pods pending = ${PODSPENDING}"
        PODSPENDING=$(kubectl get pods --namespace=kafka | awk '{print $2}' | cut -d '/' -f1 | grep 0 | wc -l | awk '{print $1}')
        sleep 10
    done
}

function testKafka {
    echo "Testing the Kafka service"
    kubectl apply -f $HOME/$REPODIR/kafka/test/
    #wait for the tests to complete. This could take a couple of minutes
    TESTSPENDING=$(kubectl get pods -l test-type=readiness --namespace=test-kafka | awk '{print $2}' | cut -d '/' -f1 | grep 0 | wc -l | awk '{print $1}')
    while [ "${TESTSPENDING}" != "0" ]; do
        echo "Waiting on Kafka test cases to complete. Tests pending = ${TESTSPENDING}"
        TESTSPENDING=$(kubectl get pods -l test-type=readiness --namespace=test-kafka | awk '{print $2}' | cut -d '/' -f1 | grep 0 | wc -l | awk '{print $1}')
        sleep 10
    done
}

function whatsRunning {
    echo "Check what is running"
    kubectl get all -n kafka
}

main

# setup security group for Kafka LB
# $SDIR/elb-sg-rule.sh
