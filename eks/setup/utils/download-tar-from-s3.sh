#!/bin/bash
# download tar file from s3, and untar it to the working directory
# usage: download-tar-from-s3 key local.tar
#    e.g., ./download-tar-from-s3.sh myshare/foo.tar local-folder

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
source ${CONFIGDIR}/env.sh

sudo aws s3api get-object --bucket ${S3_BUCKET} --key ${1} ${2}.tar
sudo tar -xf ${2}.tar -C ${2}
sudo rm ${2}.tar
