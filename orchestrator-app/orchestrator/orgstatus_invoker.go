package main

import (
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
)

var client *lambda.Lambda
var orgstatusFunc string

func init() {
	// Create Lambda service client
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	region := os.Getenv("FUNC_REGION")
	client = lambda.New(sess, &aws.Config{Region: &region})
	orgstatusFunc = os.Getenv("ORGSTATUS_FUNC")
}

func invokeOrgStatus(orgID string) (string, error) {
	// construct org-status request for flogo lambda function
	log.Printf("invokeOrgStatus for provider: %s\n", orgID)
	payload := fmt.Sprintf("{\"orgID\": \"%s\"}", orgID)

	log.Printf("Send request to org-status lambda %s: %s\n", orgstatusFunc, payload)
	result, err := client.Invoke(&lambda.InvokeInput{
		FunctionName: &orgstatusFunc,
		Payload:      []byte(payload)})
	if err != nil {
		log.Printf("Error calling %s: %+v\n", orgstatusFunc, err)
		return "", err
	}

	log.Printf("StatusCode: %d\n", result.StatusCode)
	msg := string(result.Payload)
	log.Printf("Returned org-status message: %s\n", msg)
	return msg, nil
}
