package main

// ReferenceData data
type ReferenceData struct {
	Reference string `json:"reference"`
}

// EligibilityRequest data
type EligibilityRequest struct {
	ResourceType string        `json:"resourceType"`
	ID           string        `json:"ID"`
	Status       string        `json:"status,omitempty"`
	Patient      ReferenceData `json:"patient,omitempty"`
	Created      string        `json:"created,omitempty"`
	Organization ReferenceData `json:"organization,omitempty"`
	Insurer      ReferenceData `json:"insurer,omitempty"`
	Coverage     ReferenceData `json:"coverage,omitempty"`
}

// EligibilityResponse data
type EligibilityResponse struct {
	ResourceType string        `json:"resourceType"`
	ID           string        `json:"ID"`
	Status       string        `json:"status,omitempty"`
	Patient      ReferenceData `json:"patient,omitempty"`
	Created      string        `json:"created,omitempty"`
	Organization ReferenceData `json:"organization,omitempty"`
	Insurer      ReferenceData `json:"insurer,omitempty"`
	Coverage     ReferenceData `json:"coverage,omitempty"`
	Request      ReferenceData `json:"request,omitempty"`
	Disposition  string        `json:"disposition,omitempty"`
	Inforce      bool          `json:"inforce"`
	SysError     []SystemError `json:"error,omitempty"`
}

// ErrorCode data
type ErrorCode struct {
	System string `json:"system,omitempty"`
	Code   string `json:"code,omitempty"`
}

// ErrorCodeList data
type ErrorCodeList struct {
	Coding []ErrorCode `json:"coding,omitempty"`
}

// SystemError data
type SystemError struct {
	Code ErrorCodeList `json:"code,omitempty"`
}
