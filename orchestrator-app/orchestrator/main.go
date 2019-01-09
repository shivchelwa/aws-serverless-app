package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/google/uuid"
)

func errorResponse(system string, errCode string, reqID string) string {
	resp := EligibilityResponse{
		ResourceType: "EligibilityResponse",
		ID:           uuid.New().String(),
		Status:       "active",
		Created:      time.Now().Format("2006-01-02"),
	}
	if reqID != "" {
		resp.Request = ReferenceData{
			Reference: reqID,
		}
	}
	resp.SysError = []SystemError{
		SystemError{
			Code: ErrorCodeList{
				Coding: []ErrorCode{
					ErrorCode{
						System: system,
						Code:   errCode,
					},
				},
			},
		},
	}
	if msg, err := json.Marshal(resp); err == nil {
		return string(msg)
	}
	return ""
}

func successResponse(req *EligibilityRequest, inforce bool) string {
	resp := EligibilityResponse{
		ResourceType: "EligibilityResponse",
		ID:           uuid.New().String(),
		Status:       "active",
		Created:      time.Now().Format("2006-01-02"),
		Organization: req.Organization,
		Insurer:      req.Insurer,
		Coverage:     req.Coverage,
		Request: ReferenceData{
			Reference: req.ID,
		},
		Inforce: inforce,
	}
	if inforce {
		resp.Disposition = "Policy is currently in-force"
	} else {
		resp.Disposition = "Policy is not in-force"
	}

	if msg, err := json.Marshal(resp); err == nil {
		return string(msg)
	}
	return ""
}

func checkCoverage(reqBody string) (*EligibilityResponse, error) {
	coverageURL := os.Getenv("COVERAGE_URL")
	log.Printf("Send request to coverage service at %s\n", coverageURL)
	startTime := time.Now()
	resp, err := http.Post(coverageURL, "application/json", bytes.NewBuffer([]byte(reqBody)))
	log.Printf("Coverage service elapsed time %s\n", time.Since(startTime))

	if err != nil {
		log.Printf("Error returned from coverage service: %+v\n", err)
		return nil, err
	}
	if resp.StatusCode != 200 {
		log.Printf("Coverage service returned status code: %d\n", resp.StatusCode)
		return nil, fmt.Errorf("Coverage service returned non-200 code: %d", resp.StatusCode)
	}
	var respBody EligibilityResponse
	if err := json.NewDecoder(resp.Body).Decode(&respBody); err != nil {
		log.Printf("Failed to parse response from coverage service: %+v\n", err)
		return nil, err
	}
	return &respBody, nil
}

func checkOrgStatus(orgID string) (bool, error) {
	log.Printf("Invoke org-status service for provider %s\n", orgID)
	startTime := time.Now()
	resp, err := invokeOrgStatus(orgID)
	log.Printf("OrgStatus service elapsed time %s\n", time.Since(startTime))

	if err != nil {
		log.Printf("Error invoking OrgStatus: %+v\n", err)
		return false, err
	}

	inforce, err := strconv.ParseBool(resp)
	if err != nil {
		log.Printf("Failed to convert org-status response '%s' to bool\n", resp)
		return false, fmt.Errorf("OrgStatus service returned non-bool value %s", resp)
	}

	return inforce, nil
}

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Received request: %+v\n", request)
	startTime := time.Now()

	var reqBody EligibilityRequest
	if err := json.Unmarshal([]byte(request.Body), &reqBody); err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: 400,
			Headers: map[string]string{
				"Content-Type": "application/json",
			},
			Body: errorResponse("Orchestrator", "BAD_REQUEST", ""),
		}, err
	}

	// initialize inforce
	var err error
	inforce := true
	c := make(chan string, 3)

	// Log request body to Kafka
	go func() {
		currTime := time.Now()
		publish("Eligibility Request [Orchestrator] "+request.Body, 1)
		reqPubTime := time.Since(currTime)
		c <- fmt.Sprintf(" reqPub %s", reqPubTime)
	}()

	go func() {
		currTime := time.Now()
		ok, e := checkOrgStatus(reqBody.Organization.Reference)
		if e != nil {
			err = e
			inforce = false
		} else if inforce {
			inforce = ok
		}
		orgStatusTime := time.Since(currTime)
		c <- fmt.Sprintf(" orgStatus %s", orgStatusTime)
	}()

	go func() {
		currTime := time.Now()
		resp, e := checkCoverage(request.Body)
		if e != nil {
			err = e
			inforce = false
		} else if inforce {
			inforce = resp.Inforce
		}
		coverageTime := time.Since(currTime)
		c <- fmt.Sprintf(" coverage %s", coverageTime)

	}()

	// wait for 3 tasks to complete
	var buffer bytes.Buffer
	for i := 0; i < 3; i++ {
		msg := <-c
		buffer.WriteString(msg)
		if err != nil {
			errCode := "KAFKA_ERROR"
			if strings.HasPrefix(msg, "orgStatus") {
				errCode = "ORG_STATUS_ERROR"
			} else if strings.HasPrefix(msg, "coverage") {
				errCode = "COVERAGE_ERROR"
			}
			return events.APIGatewayProxyResponse{
				StatusCode: 500,
				Headers: map[string]string{
					"Content-Type": "application/json",
				},
				Body: errorResponse("Orchestrator", errCode, reqBody.ID),
			}, err
		}
	}

	// Log response body to Kafka
	respBody := successResponse(&reqBody, inforce)
	currTime := time.Now()
	publish("Eligibility Response [Orchestrator] "+respBody, 1)
	respPubTime := time.Since(currTime)

	// Log elapsed time
	log.Printf("Orchestrator elapsed time %s: %s respPub %s\n",
		time.Since(startTime), buffer.String(), respPubTime)

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: respBody,
	}, nil
}

func main() {
	lambda.Start(handler)
}
