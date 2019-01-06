aws ecr get-login --no-include-email
aws ecr create-repository --repository-name coverage
docker tag coverage:1.0 742759186184.dkr.ecr.us-west-2.amazonaws.com/coverage:1.0
docker push 742759186184.dkr.ecr.us-west-2.amazonaws.com/coverage:1.0
aws ecr describe-images --repository-name coverage
