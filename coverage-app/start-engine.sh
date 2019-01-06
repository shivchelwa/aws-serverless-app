#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BE_HOME=~/tibcobe/be/5.5

cd ${SDIR}
${BE_HOME}/bin/be-engine --propFile ${BE_HOME}/bin/be-engine.tra -u default -c coverage.cdd Coverage.ear
