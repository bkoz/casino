# Casino Kiosk CTF Challenge

A Capture The Flag (CTF) challenge featuring Server-Side Request Forgery (SSRF) vulnerabilities in a casino kiosk web application.

## Features

- SSRF vulnerability with custom protocol handlers
- Obfuscated flag embedded in the binary
- In-memory service account token storage
- Containerized deployment ready for Kubernetes

## CI/CD Pipeline

This project uses GitHub Actions to automatically:
- Build and test the Go application
- Build multi-architecture container images (amd64/arm64)
- Push images to GitHub Container Registry (ghcr.io)
- Run security scans with Trivy
- Generate build attestations

### Workflow Triggers

The workflow runs on:
- Pushes to `main` branch
- Pull requests to `main` branch
- Git tags starting with `v*` (e.g., `v1.0.0`)

### Container Images

Images are available at: `ghcr.io/bkoz/casino`

Pull the latest image:
```bash
docker pull ghcr.io/bkoz/casino:latest
```

### Image Tags

- `latest` - Latest build from main branch
- `main` - Main branch builds
- `v*` - Semantic version tags
- `pr-*` - Pull request builds
- `main-<sha>` - Commit-specific builds

## Local Development

### Prerequisites

- Go 1.21 or later
- Docker (optional, for containerized testing)

### Build and Test

Using Make:
```bash
# Run tests
make test

# Build binary
make build

# Run locally (requires STOLEN_SA_TOKEN env var)
make run

# Build Docker image
make docker-build

# Run Docker container
make docker-run
```

Using Go directly:
```bash
# Run tests
go test -v ./...

# Build
go build -o casino-kiosk .

# Run (set STOLEN_SA_TOKEN first)
export STOLEN_SA_TOKEN="test-token"
./casino-kiosk
```

### Running the Container

```bash
docker run -p 8080:8080 \
  -e STOLEN_SA_TOKEN="dummy-token" \
  ghcr.io/bkoz/casino:latest
```

Access the application at: http://localhost:8080

## Deployment

The container is designed to run in Kubernetes environments. It expects:
- `STOLEN_SA_TOKEN` environment variable
- Port 8080 exposed
- Non-root user execution (UID 1000)

## Security

This is a CTF challenge intentionally containing vulnerabilities for educational purposes. Do not use in production environments.

## License

See [LICENSE](LICENSE) file.
