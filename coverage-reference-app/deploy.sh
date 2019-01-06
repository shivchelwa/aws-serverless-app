#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/elasticache
source ${CONFIGDIR}/env.sh

appName=coverage-reference-app

input=$(aws cloudformation describe-stacks --stack-name ${appName} --query 'Stacks[].Outputs[].OutputValue' --output text)
echo "check original stack ${appName} values: ${input}"

cd ${SDIR}
echo "Set template to use Redis cache endpoint: ${REDIS_EP}"
sed -i -e "s/REDIS_URL:.*/REDIS_URL: ${REDIS_EP}/" ./template.yaml

# deploy org-reference-app lambda
make build
sam package --template-file template.yaml --output-template-file packaged.yaml --s3-bucket ${S3_BUCKET}
aws cloudformation deploy --template-file packaged.yaml --stack-name ${appName} --capabilities CAPABILITY_IAM

status=$(aws cloudformation describe-stacks --stack-name ${appName} --query 'Stacks[].StackStatus' --output text)
while [[ "${status}" != *COMPLETE* ]]; do
  echo "waiting for stack ${appName} - current status ${status} ..."
  sleep 10
  status=$(aws cloudformation describe-stacks --stack-name ${appName} --query 'Stacks[].StackStatus' --output text)
done

# configure new lambda function
if [ -z "${input}" ]; then
  output=$(aws cloudformation describe-stacks --stack-name ${appName} --query 'Stacks[].Outputs[].OutputValue' --output text)
  array=( ${output} )
  for arn in "${array[@]}"; do
    if [[ ${arn} = arn:aws:lambda:* ]]; then
      func=${arn##*:}
      sed -i -e "s|^FUNCTION_ARN=.*|FUNCTION_ARN=${arn}|" ./env.sh
    elif [[ ${arn} = arn:aws:iam:* ]]; then
      role=${arn##*/}
    else
      api=${arn}
    fi
  done
  echo "New lambda ${appName} properties - func: $func; role: $role; api: $api"
  sed -i -e "s|^GATEWAY_URL=.*|GATEWAY_URL=${api}|" ./env.sh

  # add VPC role to the lambda role
  echo "add VPC role to ${role}"
  aws iam attach-role-policy --role-name ${role} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

  echo "configure lambda function ${func} to set SubnetIds=${VPC_SUBNETS} and SecurityGroupIds=${DEFAULT_SG}"
  source ${CONFIGDIR}/env.sh
  aws lambda update-function-configuration --vpc-config SubnetIds=${VPC_SUBNETS},SecurityGroupIds=${DEFAULT_SG} --function-name ${func}
fi

