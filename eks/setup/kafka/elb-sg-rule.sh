#!/bin/bash
# these restriction unfortunately makes kafka not accessible, so do not apply them.

cd "$( dirname "${BASH_SOURCE[0]}" )"
source ../config/env.sh

elbSgids=$(aws ec2 describe-security-groups --filters Name=description,Values=*ELB*kafka* --query 'SecurityGroups[*].GroupId' --output text)
array=( ${elbSgids} )
nodeSgid=$(aws ec2 describe-security-groups --filters Name=group-name,Values=eksctl-${EKS_STACK}-nodegroup-0-SG* --query 'SecurityGroups[*].GroupId' --output text)
bastionSgid=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${EFS_STACK}-InstanceSecurityGroup-* --query 'SecurityGroups[*].GroupId' --output text)

for sgid in "${array[@]}"; do
  echo "set Kafka LB rule for node sg ${nodeSgid}, ${bastionSgid} and ${MYCIDR} in security group ${sgid}"
  aws ec2 revoke-security-group-ingress --group-id ${sgid} --protocol tcp --port 9094 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id ${sgid} --protocol tcp --port 9094 --source-group ${nodeSgid}
  aws ec2 authorize-security-group-ingress --group-id ${sgid} --protocol tcp --port 9094 --source-group ${bastionSgid}
  aws ec2 authorize-security-group-ingress --group-id ${sgid} --protocol tcp --port 9094 --cidr ${MYCIDR}
done
