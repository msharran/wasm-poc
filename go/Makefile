.PHONY: build,fmt,generate_json_marshallers

build: fmt generate_json_marshallers
	tinygo build -target=wasi -o=../bin/go.wasm ./...

fmt:
	go fmt ./...

generate_json_marshallers:
	cd types && easyjson -snake_case types.go
