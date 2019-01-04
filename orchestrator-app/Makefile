.PHONY: deps clean build

deps:
	go get -u ./...

clean: 
	rm -rf ./orchestrator/orchestrator
	
build:
	GOOS=linux GOARCH=amd64 go build -o orchestrator/orchestrator ./orchestrator
