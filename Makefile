.PHONY: help

help: ## List of commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build image
	@echo "Building ton docker image"
	scripts/download-jar.sh
	docker buildx build --platform linux/amd64 -t ton-local -f Dockerfile .

test-sidecar: ## Test sidecar
	go test ./sidecar/...