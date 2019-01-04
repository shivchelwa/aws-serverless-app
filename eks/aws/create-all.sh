#!/bin/bash
# create EKS cluster and setup EFS
# usage: create-all.sh [ env [ region ]]
# e.g., create-all.sh dev us-west-2
# better first "source env.sh dev us-west-2", so all other commands would use the same environment

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [ "$#" -gt 0 ]; then
  export ENV_NAME=${1}
fi
if [ "$#" -gt 1 ]; then
  export AWS_REGION=${2}
fi
source env.sh
sed -i -e "s/^EKS_STACK=.*/EKS_STACK=${EKS_STACK}/g" ../setup/config/env.sh

# verify aws CLI installation
region=`aws configure get region`
if [ -z "${region}" ]; then
  echo "Error: AWS CLI is not configured."
  echo "install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html#install-tool-bundled"
  echo "to configure aws user and region: 'aws configure'"
  echo "to verify aws user: 'aws sts get-caller-identity'"
  exit 1
fi

# create key pair for managing EFS
./create-key-pair.sh

# create s3 buckets for sharing files
./create-s3-bucket.sh

# create EKS cluster and setup EKS nodes
./create-cluster.sh
./setup-eks-node.sh

# create EFS volume and bastion host for EFS client
./deploy-efs.sh

# set rules for security groups, so it won't open to the world
./efs-sg-rule.sh

# initilaize bastion host
./setup-bastion.sh

# setup role and vpc for lambda functions
# note: I cannot make lambda in this pvc to open to other vpc,
# this script is not used, use default vpc as scripts in elasticache folder
#./setup-lambda.sh

# ssh to bastion host and start kafka 
./start-kafka.sh

# verify installation of jq
jq --version
if [ $? -ne 0 ]; then
  echo ""
  echo "jq is not in PATH. You will need it to run cleanup scripts."
  echo "jq installation: https://github.com/stedolan/jq/wiki/Installation"
fi
