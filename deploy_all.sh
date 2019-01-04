#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

${SDIR}/elasticache/create-all.sh
${SDIR}/org-reference-app/deploy.sh
${SDIR}/flogo-rules-app/deploy.sh
${SDIR}/flogo-org-status-app/deploy.sh
${SDIR}/coverage-mock-app/deploy.sh
${SDIR}/orchestrator-app/deploy.sh

