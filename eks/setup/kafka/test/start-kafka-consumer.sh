#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/../config
source ${CONFIGDIR}/env.sh

$HOME/kafka/bin/kafka-console-consumer.sh --bootstrap-server ${EXTERNAL_BROKER_HOST}:${EXTERNAL_BROKER_PORT} --topic test --from-beginning
