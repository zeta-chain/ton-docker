help: ## List of commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build image
	@echo "Building ton docker image"
	docker buildx build -t ton-local -f Dockerfile .

build-x86: ## Build x86 image
	@echo "Building ton docker image for x86"
	docker buildx build --platform linux/amd64 -t ton-local -f Dockerfile .

build-no-cache: # Build w/o cache
	@echo "Building ton docker image"
	scripts/download-jar.sh
	docker buildx build --no-cache -t ton-local -f Dockerfile .

test-sidecar: ## Test sidecar
	go test ./sidecar/...

.PHONY: help build build-x86 build-no-cache test-sidecar