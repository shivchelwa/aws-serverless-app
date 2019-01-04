#!/bin/bash

SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
source ${CONFIGDIR}/env.sh

# upload a specified file or folder to an s3 folder;
# folder will be uploaded as a single tar file
# usage: upload file s3Folder
function upload {
  local path=${1}
  if [ -d ${path} ]; then
    echo "create ${path}.tar"
    sudo tar -cf ${path}.tar -C $(dirname ${path}) $(basename ${path})
    path=${path}.tar
  fi
  sudo chown ec2-user ${path}
  local key=$(basename ${path})
  local folder=${2:-""}
  if [ ! -z ${folder} ]; then
    key=${folder}/${key}
  fi

  echo "upload ${path} to s3 bucket ${S3_BUCKET} as ${key}."
  aws s3api put-object --bucket ${S3_BUCKET} --key ${key} --body ${path}
  aws s3api put-object-acl --bucket ${S3_BUCKET} --key ${key} --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
  aws s3api put-object-acl --bucket ${S3_BUCKET} --key ${key} --acl public-read
}

upload $*