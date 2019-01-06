#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SDIR}/env.sh

cov=${1:-"C-000001"}
num=${2:-"20"}

result=$(curl "${GATEWAY_URL}?key=${cov}" --output -)
if [[ ${result} == *error* ]]; then
  echo "initialize org cache with ${num} coverages"
  curl "${GATEWAY_URL}" -H "Content-Type: text/plain" -d "init=20" --output -
  echo ""
fi
#curl "${GATEWAY_URL}" -H "Content-Type: text/plain" -d "cov1=cov1,2019-01-01,2019-12-01" --output -
result=$(curl "${GATEWAY_URL}?key=${cov}" --output -)
echo ${result}
if [[ ${result} == *error* ]]; then
  echo "coverage ${cov} does not exist"
  echo "choose coverage id between C-000000 to C-000019"
fi

