# number of kafka brokers
KAFKA_COUNT=3

##### LoadBalancer info
# generated Kafka LB host:port
# -- these vars are created on bastion host only if Kafka is started on bastion host.
# -- use eks/aws/start-kafka.sh to set the broker info in this file, so it can be used by lambda config
EXTERNAL_BROKER_HOST=
EXTERNAL_BROKER_PORT=
EXTERNAL_KAFKA_0_HOST=
EXTERNAL_KAFKA_0_PORT=
EXTERNAL_KAFKA_1_HOST=
EXTERNAL_KAFKA_1_PORT=
EXTERNAL_KAFKA_2_HOST=
EXTERNAL_KAFKA_2_PORT=

##### pre-configured variables in EKS/EFS/S3
# used to configure EC2 security group by kafka elb-sg-rule.sh
EKS_STACK=poc-eks-stack
EFS_STACK=poc-efs-client
MYCIDR=
# used to mount EFS volume by NFS
EFS_SERVER=
# name of the test environment
ENV_NAME=poc
# used to share data across region and accounts
S3_BUCKET=
# used to create Redis cache and configure lambda on the EKS VPC 
# -- Redis created on this VPC does not work, so following vars are not used.
EKS_VPC=
EKS_SUBNET=
EKS_SG=
LAMBDA_ROLE=
REDIS_EP=
