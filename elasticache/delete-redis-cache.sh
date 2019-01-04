#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SDIR}/env.sh

echo "delete Redis cache cluster ${REDIS_ID}"
aws elasticache delete-cache-cluster --cache-cluster-id ${REDIS_ID}

