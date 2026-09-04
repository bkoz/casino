.PHONY: help build test run docker-build docker-run clean

# Default target
help:
	@echo "Casino Kiosk CTF Challenge - Build Targets"
	@echo "==========================================="
	@echo "make build        - Build the Go binary"
	@echo "make test         - Run tests"
	@echo "make run          - Run the application locally"
	@echo "make docker-build - Build Docker image"
	@echo "make docker-run   - Run Docker container locally"
	@echo "make clean        - Remove build artifacts"

# Build the Go binary
build:
	@echo "Building casino-kiosk..."
	go build -o casino-kiosk .

# Run tests
test:
	@echo "Running tests..."
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out

# Run the application locally (requires STOLEN_SA_TOKEN env var)
run:
	@echo "Running casino-kiosk..."
	@if [ -z "$$STOLEN_SA_TOKEN" ]; then \
		echo "Warning: STOLEN_SA_TOKEN not set, using dummy value"; \
		export STOLEN_SA_TOKEN="dummy-token-for-local-testing"; \
	fi; \
	STOLEN_SA_TOKEN="$${STOLEN_SA_TOKEN}" PORT=8080 go run .

# Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t casino-kiosk:latest .

# Run Docker container locally
docker-run: docker-build
	@echo "Running Docker container..."
	docker run -p 8080:8080 \
		-e STOLEN_SA_TOKEN="dummy-token-for-local-testing" \
		-e PORT=8080 \
		casino-kiosk:latest

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f casino-kiosk
	rm -f coverage.out
	go clean
