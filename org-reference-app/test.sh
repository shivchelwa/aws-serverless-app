#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SDIR}/env.sh

org=${1:-"P-000001"}
num=${2:-"20"}

result=$(curl "${GATEWAY_URL}?key=${org}" --output -)
if [[ ${result} == *error* ]]; then
  echo "initialize org cache with ${num} providers"
  curl "${GATEWAY_URL}" -H "Content-Type: text/plain" -d "init=20" --output -
  echo ""
fi
#curl "${GATEWAY_URL}" -H "Content-Type: text/plain" -d "org1=org1,Active,2018-12-01" --output -
result=$(curl "${GATEWAY_URL}?key=${org}" --output -)
echo ${result}
if [[ ${result} == *error* ]]; then
  echo "provider ${org} does not exist"
  echo "choose provider id between P-000000 to P-000019"
fi

