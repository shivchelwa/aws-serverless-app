.PHONY: deps clean build

deps:
	go get -u ./...

clean: 
	rm -rf ./orgdata/orgdata
	
build:
	GOOS=linux GOARCH=amd64 go build -o orgdata/orgdata ./orgdata
