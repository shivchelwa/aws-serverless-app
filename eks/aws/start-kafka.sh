#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source env.sh

echo "ssh on ${BASTION} to start Kafka ..."
ssh -i ${SSH_PRIVKEY} -o "StrictHostKeyChecking no" ec2-user@${BASTION} << EOF
  cd scripts/kafka
  ./start-kafka.sh
EOF

# set kafka broker host and port
kafkahost=$(kubectl get svc "external-broker" -n kafka -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
kafkaport=$(kubectl get svc "external-broker" -n kafka -o jsonpath='{.spec.ports[*].port}')
echo "started Kafka at ${kafkahost}:${kafkaport}"
sed -i -e "s|^EXTERNAL_BROKER_HOST=.*|EXTERNAL_BROKER_HOST=${kafkahost}|" ../setup/config/env.sh
sed -i -e "s|^EXTERNAL_BROKER_PORT=.*|EXTERNAL_BROKER_PORT=${kafkaport}|" ../setup/config/env.sh
