#!/bin/bash
# use 'deploy.sh mock' if test against mock coverage app

option=${1:-""}

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$(dirname "${SDIR}")

appName=orchestrator-app

input=$(aws cloudformation describe-stacks --stack-name ${appName} --query 'Stacks[].Outputs[].OutputValue' --output text)
echo "check original stack ${appName} values: ${input}"

cd ${SDIR}
# setup environment parameters
source ${ROOT}/flogo-org-status-app/env.sh
orgstatusf=${FUNCTION_ARN##*:}
region=$(aws configure get region)
source ${ROOT}/eks/setup/config/env.sh
kafkaurl=${EXTERNAL_BROKER_HOST}:${EXTERNAL_BROKER_PORT}
if [ "${option}" == "mock" ]; then
  source ${ROOT}/coverage-mock-app/env.sh
else
  source ${ROOT}/coverage-app/env.sh
fi
coverageurl=${GATEWAY_URL}
echo "set env AWS region ${region}, org-status lambda ${orgstatusf}, Kafka URL ${kafkaurl}, Coverage URL ${coverageurl}"
sed -i -e "s|FUNC_REGION:.*|FUNC_REGION: ${region}|" ./template.yaml
sed -i -e "s|ORGSTATUS_FUNC:.*|ORGSTATUS_FUNC: ${orgstatusf}|" ./template.yaml
sed -i -e "s|KAFKA_URL:.*|KAFKA_URL: ${kafkaurl}|" ./template.yaml
sed -i -e "s|COVERAGE_URL:.*|COVERAGE_URL: ${coverageurl}|" ./template.yaml

# deploy orchestrator-app lambda
make build
source ${ROOT}/elasticache/env.sh
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
      echo "attache AWSLambdaRole to role ${role}"
      aws iam attach-role-policy --role-name ${role} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaRole
    else
      api=${arn}
    fi
  done
  echo "New lambda ${appName} properties - func: $func; role: $role; api: $api"
  sed -i -e "s|^GATEWAY_URL=.*|GATEWAY_URL=${api}|" ./env.sh
fi

