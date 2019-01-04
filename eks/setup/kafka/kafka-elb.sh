#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
source ${CONFIGDIR}/env.sh

function printKafkaLBYaml {
  local num=${2:-""}
  local svcName=${1}
  echo "
kind: Service
apiVersion: v1
metadata:
  name: ${svcName}
  namespace: kafka
spec:
  selector:
    app: kafka"
  if [ ! -z ${num} ]; then
    echo "    statefulset.kubernetes.io/pod-name: kafka-${num}"
  fi
  echo "  ports:
  - port: 9094
  type: LoadBalancer"
}

# start external ELB if no arg is specified, or
# start ELB for a broker kafka-${num} if num=0, 1, 2 ... is specified
function startKafkaLB {
  local num=${1:-""}
  local svcName="external-broker"
  if [ ! -z ${num} ]; then
    svcName="outside-${num}"
  fi

  local nlb=$(kubectl get svc ${svcName} -n kafka | grep ${svcName} | awk '{print $1}')
  if [ ! -z ${nlb} ]; then
    echo "Load balancer svc/${svcName} is already running, skip."
  else
    echo "Starting ELB service ${svcName}"
    printKafkaLBYaml ${svcName} ${num} > ${SDIR}/kafka-${svcName}.yml
    kubectl apply -f ${SDIR}/kafka-${svcName}.yml
  fi
  # wait for service to be created and hostname to be available. This could take a few seconds
  ELBHOST=$(kubectl get svc ${svcName} -n kafka -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
  ELBPORT=$(kubectl get svc ${svcName} -n kafka -o jsonpath='{.spec.ports[*].port}')
  while [[ "${ELBHOST}" != *"elb"* ]]; do
    echo "Waiting on Kafka to create service. Hostname = ${ELBHOST}"
    ELBHOST=$(kubectl get svc ${svcName} -n kafka -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
    ELBPORT=$(kubectl get svc ${svcName} -n kafka -o jsonpath='{.spec.ports[*].port}')
    sleep 10
  done

  # update env.sh with the Kafka LB host and port. This will be used to start kafka brokers
  echo "Updating env.sh with Kafka Broker service LB: ${ELBHOST}"
  local lbName="EXTERNAL_BROKER"
  if [ ! -z ${num} ]; then
    lbName="EXTERNAL_KAFKA_${num}"
  fi
  sed -i -e "s/^${lbName}_HOST=.*/${lbName}_HOST=${ELBHOST}/g" ${CONFIGDIR}/env.sh
  sed -i -e "s/^${lbName}_PORT=.*/${lbName}_PORT=${ELBPORT}/g" ${CONFIGDIR}/env.sh
}

function createKafkaELBs {
  echo "create kafka external broker ..."
  startKafkaLB
  local maxCount=$((${KAFKA_COUNT} - 1))
  for n in $(seq 0 ${maxCount}); do
    echo "create outside service for kafka-${n} ..."
    startKafkaLB ${n}
  done
}

# createKafkaELBs
