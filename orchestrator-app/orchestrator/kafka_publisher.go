package main

import (
	"log"
	"os"
	"time"

	"github.com/Shopify/sarama"
)

var config *sarama.Config
var producer sarama.SyncProducer
var kafkaConn string
var topic string

func init() {
	// setup sarama log to stdout
	//sarama.Logger = log.New(os.Stdout, "", log.Ltime)

	kafkaConn = os.Getenv("KAFKA_URL")
	topic = os.Getenv("WAYPOINTS_TOPIC")

	// producer config
	config = sarama.NewConfig()
	config.Producer.Retry.Max = 3
	config.Producer.RequiredAcks = sarama.WaitForLocal
	config.Producer.Return.Successes = true

	// async producer
	//prd, err := sarama.NewAsyncProducer([]string{kafkaConn}, config)

	// sync producer
	var err error
	if producer, err = sarama.NewSyncProducer([]string{kafkaConn}, config); err != nil {
		log.Printf("Error creating producer for Kafka %s: [%s]\n", kafkaConn, err)
		//		panic(err)
	} else {
		log.Printf("Initialized producer for topic %s on Kafka %s\n", topic, kafkaConn)
	}
}

// ack mode: -1=All, 1=Leader, 0=NoResponse
func publish(message string, ack int16) {
	// update ack mode
	if ack != int16(config.Producer.RequiredAcks) {
		config.Producer.RequiredAcks = sarama.RequiredAcks(ack)
	}

	// publish sync
	startTime := time.Now()
	msg := &sarama.ProducerMessage{
		Topic: topic,
		Value: sarama.StringEncoder(message),
	}
	log.Printf("Kafka publisher elapsed time %s\n", time.Since(startTime))

	if p, o, err := producer.SendMessage(msg); err != nil {
		log.Printf("Error publishing message '%s': [%s]\n", message, err)
	} else {
		log.Printf("published message '%s' on Partition %d Offset %d\n", message, p, o)
	}

	// publish async
	//producer.Input() <- &sarama.ProducerMessage{
}
