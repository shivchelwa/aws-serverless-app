#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${SDIR}/env.sh

aws lambda invoke --function-name ${FUNCTION_ARN} --payload "{\"orgID\":\"P-000008\"}" result.txt
cat result.txt
echo ""
