#!/bin/bash
# install amazon-efs-utils on a specified EKS nodes, or all EKS nodes if no node is specified
# usage: ./setup-eks-node.sh [ host [ host ] ]

cd "$( dirname "${BASH_SOURCE[0]}" )"
source env.sh

if [ "$#" -eq 0 ]; then
  nodeHosts=$(aws ec2 describe-instances --region ${AWS_REGION} --query 'Reservations[*].Instances[*].PublicDnsName' --output text --filters "Name=tag:Name,Values=${EKS_STACK}-0-Node" "Name=instance-state-name,Values=running")
  array=( ${nodeHosts} )
else
  array=( "$@" )
fi

for s in "${array[@]}"; do
echo "install amazon-efs-utils on host ${s}"
ssh -i ${SSH_PRIVKEY} -o "StrictHostKeyChecking no" ec2-user@${s} << EOF
  sudo yum install -y amazon-efs-utils
EOF
done
