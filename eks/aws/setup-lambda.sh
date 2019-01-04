#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
source env.sh

vpcId=$(aws eks describe-cluster --name ${EKS_STACK} --query 'cluster.resourcesVpcConfig.vpcId' --output text)
subnetIds=$(aws eks describe-cluster --name ${EKS_STACK} --query 'cluster.resourcesVpcConfig.subnetIds' --output text)
array=( ${subnetIds} )
pubSubnet=${array[0]},${array[1]},${array[2]}
sg=$(aws eks describe-cluster --name ${EKS_STACK} --query 'cluster.resourcesVpcConfig.securityGroupIds' --output text)

echo "EKS VPC vpcId: ${vpcId}; subnets: ${pubSubnet}; security-group: ${sg}"
sed -i -e "s/^EKS_VPC=.*/EKS_VPC=${vpcId}/" ../setup/config/env.sh
sed -i -e "s/^EKS_SUBNET=.*/EKS_SUBNET=${pubSubnet}/" ../setup/config/env.sh
sed -i -e "s/^EKS_SG=.*/EKS_SG=${sg}/" ../setup/config/env.sh

# setup lambda role
lambdaArn=$(aws iam get-role --role-name ${LAMBDA_ROLE} --query 'Role.Arn' --output text)
if [ -z ${lambdaArn} ]; then
  # create new lambda role
  aws iam create-role --role-name ${LAMBDA_ROLE} --assume-role-policy-document file://lambda-role.json
  aws iam attach-role-policy --role-name ${LAMBDA_ROLE} --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess
  aws iam attach-role-policy --role-name ${LAMBDA_ROLE} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  aws iam attach-role-policy --role-name ${LAMBDA_ROLE} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
  lambdaArn=$(aws iam get-role --role-name ${LAMBDA_ROLE} --query 'Role.Arn' --output text)
fi
sed -i -e "s|^LAMBDA_ROLE=.*|LAMBDA_ROLE=${lambdaArn}|" ../setup/config/env.sh
