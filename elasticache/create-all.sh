#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
./create-redis-cache.sh
./create-lambda-role.sh
./create-s3-bucket.sh

