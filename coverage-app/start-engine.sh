#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# verify BE_HOME
${BE_HOME}/bin/be-engine --help
if [ $? -ne 0 ]; then
  echo "Please set BE_HOME to TIBCO BE install root, e.g., /opt/tibco/be/5.5"
  exit 1
fi

cd ${SDIR}
${BE_HOME}/bin/be-engine --propFile ${BE_HOME}/bin/be-engine.tra -u default -c ./build/coverage.cdd ./build/Coverage.ear
