#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SDIR}/env.sh

curl "${GATEWAY_URL}" -H "Content-Type: text/plain" -d "org1,Active,2018-12-01" --output -
echo ""
#curl "${GATEWAY_URL}" -H "Content-Type: application/json" -d "{ \"id\": \"org1\", \"status\": \"Active\", \"effective\": \"2018-12-31\" }" --output -
#echo ""
