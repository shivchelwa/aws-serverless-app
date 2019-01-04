#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source env.sh

echo "ssh on ${BASTION} to stop Kafka ..."
ssh -i ${SSH_PRIVKEY} -o "StrictHostKeyChecking no" ec2-user@${BASTION} << EOF
  cd scripts/kafka
  ./stop-kafka.sh
EOF

