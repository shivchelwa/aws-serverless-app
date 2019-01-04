package main

import (
	"encoding/json"
	"log"
	"math/rand"
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
		Request: ReferenceData{
			Reference: req.ID,
		},
		Coverage: req.Coverage,
		Insurer:  req.Insurer,
		Inforce:  inforce,
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

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Received request: %+v\n", request)
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

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: successResponse(&reqBody, rand.Intn(10) <= 8),
	}, nil
}

func main() {
	lambda.Start(handler)
}
