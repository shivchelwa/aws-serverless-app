#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source env.sh

region=$(aws configure get region)
echo "delete stack ${EFS_STACK} in region ${region}"
aws cloudformation delete-stack --stack-name ${EFS_STACK}
