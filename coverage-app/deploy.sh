#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$(dirname "${SDIR}")
source ${ROOT}/eks/aws/env.sh

cd ${SDIR} 

source ${SDIR}/env.sh
sed -e "s|{{IMAGE}}.*|${IMAGE}|" ./coverage-template.yaml > coverage.yaml

source ${ROOT}/coverage-reference-app/env.sh
sed -i -e "s|{{CACHE_URL}}.*|${GATEWAY_URL}|" ./coverage.yaml

source ${ROOT}/eks/setup/config/env.sh
sed -i -e "s|{{KAFKA_URL}}.*|${EXTERNAL_BROKER_HOST}:${EXTERNAL_BROKER_PORT}|" ./coverage.yaml

# start coverage service
kubectl apply -f ./coverage.yaml

stat=$(kubectl get pods | grep coverage | awk '{print $3}')
while [ ${stat} != "Running" ]; do
  echo "Wait for coverage POD. Current state: ${stat} ..."
  sleep 10
  stat=$(kubectl get pods | grep coverage | awk '{print $3}')
done

# print LoadBalancer info
lbHost=$(kubectl get svc coverage -o jsonpath='{.status.loadBalancer.ingress[].hostname}')
lbPort=$(kubectl get svc coverage -o jsonpath='{.spec.ports[].port}')

sed -i -e "s|^GATEWAY_URL=.*|GATEWAY_URL=http://${lbHost}:${lbPort}/Channels/Coverage/coverage|" ./env.sh
echo "Coverage service is running at http://${lbHost}:${lbPort}/Channels/Coverage/coverage"