#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
source ${CONFIGDIR}/env.sh

cacheId=${ENV_NAME}-redis-cache
echo "delete Redis cache cluster ${cacheId}"
aws elasticache delete-cache-cluster --cache-cluster-id ${cacheId}

groupName=${ENV_NAME}-subnet-group
echo "delete cache subnet group ${groupName} for Redis"
aws elasticache delete-cache-subnet-group \
  --cache-subnet-group-name ${groupName}

