#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SDIR}/env.sh

cacheId=${1:-"poc-redis-cache"}
nodeType=cache.t2.small
cacheNodes=1
region=$(aws configure get region)
azone=${region}a

# create redis cache in default VPC using devault security group
vpcId=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[].VpcId' --output text)
vpcSubnets=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${vpcId} --query 'Subnets[].SubnetId' --output text)
array=( ${vpcSubnets} )
cacheSubnets=${array[0]},${array[1]},${array[2]}

defaultSgid=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=${vpcId} Name=group-name,Values=default --query 'SecurityGroups[].GroupId' --output text)

aws elasticache create-cache-cluster --cache-cluster-id ${cacheId} \
  --cache-node-type ${nodeType} --engine redis --num-cache-nodes ${cacheNodes} \
  --preferred-availability-zone ${azone} \
  --security-group-ids ${defaultSgid}

status=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cacheId} --query 'CacheClusters[].CacheClusterStatus' --output text)
while [ ${status} != "available" ]; do
  echo "wait for redis cache ${cacheId} - current status ${status} ..."
  sleep 10
  status=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cacheId} --query 'CacheClusters[].CacheClusterStatus' --output text)
done

echo "open default security group for redis port 6379"
aws ec2 authorize-security-group-ingress --group-id ${defaultSgid} --protocol tcp --port 6379 --cidr 0.0.0.0/0

cacheAddr=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cacheId} --show-cache-node-info --query='CacheClusters[].CacheNodes[].Endpoint.Address' --output text)
cachePort=$(aws elasticache describe-cache-clusters --cache-cluster-id ${cacheId} --show-cache-node-info --query='CacheClusters[].CacheNodes[].Endpoint.Port' --output text)
sed -i -e "s/^REDIS_EP=.*/REDIS_EP=${cacheAddr}:${cachePort}/g" ${SDIR}/env.sh
sed -i -e "s/^REDIS_ID=.*/REDIS_ID=${cacheId}/g" ${SDIR}/env.sh
sed -i -e "s/^DEFAULT_VPC=.*/DEFAULT_VPC=${vpcId}/g" ${SDIR}/env.sh
sed -i -e "s/^VPC_SUBNETS=.*/VPC_SUBNETS=${cacheSubnets}/g" ${SDIR}/env.sh
sed -i -e "s/^DEFAULT_SG=.*/DEFAULT_SG=${defaultSgid}/g" ${SDIR}/env.sh
