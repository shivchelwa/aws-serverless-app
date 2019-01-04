#!/bin/bash
# set AWS environment for a specified $ENV_NAME and $AWS_REGION
# usage: source env.sh [env [region]]
# input arguments are ignored if the env ${ENV_NAME} and ${AWS_REGION} are already defined
# default value: ENV_NAME="eks", AWS_REGION="us-west-2"

# return the full path of this script
function getScriptDir {
  local src="${BASH_SOURCE[0]}"
  while [ -h "$src" ]; do
    local dir ="$( cd -P "$( dirname "$src" )" && pwd )"
    src="$( readlink "$src" )"
    [[ $src != /* ]] && src="$dir/$src"
  done
  cd -P "$( dirname "$src" )" 
  pwd
}

export EKS_NODE_COUNT=3
export EKS_NODE_TYPE=t2.medium
#export EKS_NODE_TYPE=m5.xlarge

if [[ -z "${ENV_NAME}" ]]; then
  export ENV_NAME=${1:-"poc"}
fi
if [[ -z "${AWS_REGION}" ]]; then
  export AWS_REGION=${2:-"us-west-2"}
fi

export AWS_ZONES=${AWS_REGION}a,${AWS_REGION}b,${AWS_REGION}c
export AWS_CLI_HOME=${HOME}/.aws
export EKS_STACK=${ENV_NAME}-eks-stack
export EFS_STACK=${ENV_NAME}-efs-client
export S3_BUCKET=${ENV_NAME}-s3-share
export EFS_VOLUME=vol-${ENV_NAME}
export LAMBDA_ROLE=${ENV_NAME}-lambda-role
export BASTION=

export SCRIPT_HOME=$(getScriptDir)
export KUBECONFIG=${SCRIPT_HOME}/config/config-${ENV_NAME}.yaml
export EFS_CONFIG=${SCRIPT_HOME}/config/${EFS_STACK}.yaml
export KEYNAME=${ENV_NAME}-keypair
export SSH_PUBKEY=${SCRIPT_HOME}/config/${KEYNAME}.pub
export SSH_PRIVKEY=${SCRIPT_HOME}/config/${KEYNAME}.pem

aws configure set region ${AWS_REGION}

if [ ! -f ${SSH_PRIVKEY} ]; then
  mkdir -p ${SCRIPT_HOME}/config
fi
