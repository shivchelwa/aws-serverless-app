#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
source ${CONFIGDIR}/env.sh

IFS=',' read -r -a subnets <<< "${EKS_SUBNET}"
echo "create Redis cache cluster in EKS subnets: ${subnets[0]} ${subnets[1]} ${subnets[2]}"

groupName=${ENV_NAME}-subnet-group
cacheGroup=$(aws elasticache describe-cache-subnet-groups --query='CacheSubnetGroups[].CacheSubnetGroupName' | grep ${groupName})
if [ -z ${cacheGroup} ]; then
  echo "create cache subnet group ${groupName} for Redis"
  aws elasticache create-cache-subnet-group \
    --cache-subnet-group-name ${groupName} \
    --cache-subnet-group-description "${ENV_NAME} cache subnet group" \
    --subnet-ids ${subnets[0]} ${subnets[1]} ${subnets[2]}
fi

cacheId=${ENV_NAME}-redis-cache
cacheCluster=$(aws elasticache describe-cache-clusters --query='CacheClusters[].CacheClusterId' | grep ${cacheId})
if [ -z ${cacheCluster} ]; then
  echo "create Redis cache cluster ${cacheId}"
  aws elasticache create-cache-cluster --cache-cluster-id ${cacheId} \
    --cache-node-type cache.t2.small --engine redis --num-cache-nodes 1 \
    --cache-subnet-group-name ${groupName} \
    --security-group-ids ${EKS_SG}
  aws ec2 authorize-security-group-ingress --group-id ${EKS_SG} --protocol tcp --port 6379 --cidr 0.0.0.0/0
fi

cacheAddr=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cacheId} --show-cache-node-info --query='CacheClusters[].CacheNodes[].Endpoint.Address' --output text)
cachePort=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cacheId} --show-cache-node-info --query='CacheClusters[].CacheNodes[].Endpoint.Port' --output text)
sed -i -e "s/^REDIS_EP=.*/REDIS_EP=${cacheAddr}:${cachePort}/g" ${CONFIGDIR}/env.sh
