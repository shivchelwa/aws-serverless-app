#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

roleName=basic-lambda-role

# setup lambda role
lambdaArn=$(aws iam get-role --role-name ${roleName} --query 'Role.Arn' --output text)
if [ -z ${lambdaArn} ]; then
  # create new lambda role
  aws iam create-role --role-name ${roleName} --assume-role-policy-document file://lambda-role.json
  aws iam attach-role-policy --role-name ${roleName} --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess
  aws iam attach-role-policy --role-name ${roleName} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaRole
  aws iam attach-role-policy --role-name ${roleName} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
  lambdaArn=$(aws iam get-role --role-name ${roleName} --query 'Role.Arn' --output text)
fi
sed -i -e "s|^LAMBDA_ROLE=.*|LAMBDA_ROLE=${lambdaArn}|" ./env.sh
