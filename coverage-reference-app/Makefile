.PHONY: deps clean build

deps:
	go get -u ./...

clean: 
	rm -rf ./coveragedata/coveragedata
	
build:
	GOOS=linux GOARCH=amd64 go build -o coveragedata/coveragedata ./coveragedata
