package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
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
		log.Printf("Coverage service returned status code: %s\n", resp.StatusCode)
		return nil, fmt.Errorf("Coverage service returned non-200 code: %s", resp.StatusCode)
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

	// Log request body to Kafka
	publish("Eligibility Request [Orchestrator] "+request.Body, 1)
	reqPubTime := time.Since(startTime)
	currTime := time.Now()

	inforce, err := checkOrgStatus(reqBody.Organization.Reference)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: 500,
			Headers: map[string]string{
				"Content-Type": "application/json",
			},
			Body: errorResponse("Orchestrator", "ORG_STATUS_ERROR", reqBody.ID),
		}, err
	}
	orgStatusTime := time.Since(currTime)
	currTime = time.Now()

	if inforce {
		resp, err := checkCoverage(request.Body)
		if err != nil {
			return events.APIGatewayProxyResponse{
				StatusCode: 500,
				Headers: map[string]string{
					"Content-Type": "application/json",
				},
				Body: errorResponse("Orchestrator", "COVERAGE_ERROR", reqBody.ID),
			}, err
		}
		inforce = resp.Inforce
	}
	coverageTime := time.Since(currTime)
	currTime = time.Now()

	// Log response body to Kafka
	respBody := successResponse(&reqBody, inforce)
	publish("Eligibility Response [Orchestrator] "+respBody, 1)
	respPubTime := time.Since(currTime)

	// Log elapsed time
	log.Printf("Orchestrator elapsed time %s: reqPub %s orgStat %s coverage %s respPub %s\n",
		time.Since(startTime), reqPubTime, orgStatusTime, coverageTime, respPubTime)

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
