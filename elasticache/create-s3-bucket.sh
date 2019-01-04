#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
bucket=${1:-"poc-sam-app"}

# check if the bucket exists already
aws s3api list-buckets --query "Buckets[].Name" --out text | grep ${bucket}
if [ $? -ne 0 ]; then
  region=$(aws configure get region)
  echo "create s3 bucket ${bucket} in region ${region}"
  aws s3api create-bucket --bucket ${bucket} --region ${region} --create-bucket-configuration LocationConstraint=${region}
  aws s3api put-bucket-acl --bucket ${bucket} --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
  aws s3api put-bucket-acl --bucket ${bucket} --acl public-read
else
  echo "s3 bucket ${bucket} already exists, skip."
fi

echo "set S3_BUCKET to ${bucket} for uploading lambda functions"
sed -i -e "s/^S3_BUCKET=.*/S3_BUCKET=${bucket}/" ./env.sh
