#!/bin/bash
# install kafka 1.0.2 on bastion host to test kafka producer/consumer.

if [ ! -d $HOME/kafka ]; then
  # download kafka 1.0.2
  mkdir $HOME/kafka
  cd $HOME/kafka
  curl https://archive.apache.org/dist/kafka/1.0.2/kafka_2.11-1.0.2.tgz > kafka.tgz
  tar -xvzf kafka.tgz --strip 1
fi
