#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT=$(dirname "${SDIR}")

appName=org_status_app

# check flogo-cli installation
which flogo
if [ $? -ne 0 ]; then
  echo "You must install flogo-cli first"
  exit 1
fi

# cleanup AWS if lambda function already exists
aws lambda get-function --function-name ${appName}
if [ $? -eq 0 ]; then
  echo "delete old lambda ${appName}"
  aws lambda delete-function --function-name ${appName}
fi

cd ${SDIR}
# cleanup old local files
if [ -d ${appName} ]; then
  echo "cleanup old content from directory ${appName} ..."
  rm -Rf ${appName}
fi

# setup called lambda arn in flow model
region=$(aws configure get region)
echo "set AWS region to ${region}"
sed -e "s|{{AWS_REGION}}|${region}|g" ./${appName}-template.json > ${appName}.json

source ${ROOT}/org-reference-app/env.sh
echo "set org-data lambda to ${FUNCTION_ARN}"
sed -i -e "s|{{OrgdataFunction}}|${FUNCTION_ARN}|" ./${appName}.json

source ${ROOT}/flogo-rules-app/env.sh
echo "set flogo-rules lambda to ${FUNCTION_ARN}"
sed -i -e "s|{{FlogoRulesFunction}}|${FUNCTION_ARN}|" ./${appName}.json

echo "generate source code for ${appName}"
flogo create -f ${appName}.json ${appName}

echo "build lambda shim for ${appName}"
cd ${appName}
flogo build -e -shim start_flow_as_a_function_in_lambda

echo "deploy lambda function ${appName}"
source ${ROOT}/elasticache/env.sh
cd src/${appName}
aws lambda create-function --function-name org_status_app --runtime go1.x --role ${LAMBDA_ROLE} --handler handler --zip-file "fileb://handler.zip"

# write out lambda function ARN for testing
arn=$(aws lambda get-function --function-name org_status_app --query 'Configuration.FunctionArn' --output text)
echo "deployed lambda ${arn}"
cd ${SDIR}
sed -i -e "s|^FUNCTION_ARN=.*|FUNCTION_ARN=${arn}|" ./env.sh
