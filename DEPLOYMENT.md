# Deployment Guide

This document explains how to deploy the Casino Kiosk CTF challenge using the automated GitHub Actions workflow.

## GitHub Actions Workflow

The repository includes a comprehensive CI/CD pipeline that automatically builds, tests, and publishes container images to GitHub Container Registry (GHCR).

### Workflow Overview

**File**: `.github/workflows/build-and-push.yml`

The workflow consists of three jobs:

1. **Test** - Runs Go tests and checks code quality
2. **Build and Push** - Builds multi-arch container images and pushes to GHCR
3. **Security Scan** - Scans images for vulnerabilities using Trivy

### Setup Requirements

#### 1. Enable GitHub Packages

The workflow uses GitHub's built-in `GITHUB_TOKEN` for authentication, which is automatically available. No additional secrets needed!

#### 2. Enable GitHub Actions

Make sure GitHub Actions is enabled for your repository:
- Go to repository Settings → Actions → General
- Ensure "Allow all actions and reusable workflows" is selected

#### 3. Configure Package Permissions

For public images (recommended for CTF challenges):
- Go to the repository on GitHub
- After the first successful workflow run, a package will be created
- Navigate to the package (Packages section on your profile/org)
- Settings → Change visibility → Public (if desired)

### Triggering the Workflow

The workflow runs automatically on:

- **Push to main**: Builds and tags as `latest` and `main`
- **Pull Requests**: Builds and tags as `pr-<number>`
- **Version Tags**: Push a tag like `v1.0.0` for versioned releases

Example versioned release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Manual Workflow Trigger

You can also manually trigger the workflow:
1. Go to Actions tab in GitHub
2. Select "Build, Test, and Push Container"
3. Click "Run workflow"

## Image Tags and Versions

After the workflow runs, images are available at:
```
ghcr.io/bkoz/casino:<tag>
```

Available tags:
- `latest` - Latest main branch build
- `main` - Main branch builds
- `v1.0.0` - Semantic version tags
- `pr-123` - Pull request builds
- `main-abc1234` - Commit SHA builds

## Using the Container

### Pull from GHCR

```bash
# Pull latest
docker pull ghcr.io/bkoz/casino:latest

# Pull specific version
docker pull ghcr.io/bkoz/casino:v1.0.0
```

### Run Locally

```bash
docker run -p 8080:8080 \
  -e STOLEN_SA_TOKEN="dummy-token-for-testing" \
  ghcr.io/bkoz/casino:latest
```

### Deploy to Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: casino-kiosk
spec:
  replicas: 1
  selector:
    matchLabels:
      app: casino-kiosk
  template:
    metadata:
      labels:
        app: casino-kiosk
    spec:
      containers:
      - name: casino-kiosk
        image: ghcr.io/bkoz/casino:latest
        ports:
        - containerPort: 8080
        env:
        - name: STOLEN_SA_TOKEN
          value: "your-token-here"
        - name: PORT
          value: "8080"
---
apiVersion: v1
kind: Service
metadata:
  name: casino-kiosk
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: casino-kiosk
```

## Workflow Features

### Multi-Architecture Support

Images are built for both:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64/Apple Silicon)

### Build Caching

The workflow uses GitHub Actions cache to speed up builds:
- Layer caching across workflow runs
- Faster builds for unchanged dependencies

### Security Features

1. **Trivy Scanning**: Automatically scans images for CVEs
2. **SARIF Upload**: Results uploaded to GitHub Security tab
3. **Build Attestations**: Cryptographic proof of build provenance
4. **Non-root User**: Container runs as UID 1000, not root

### Metadata and Labels

Images include OCI-compliant labels:
- Source repository
- Build date and commit SHA
- Version information
- License and description

## Monitoring Workflow Runs

1. Go to the **Actions** tab in your repository
2. Click on a workflow run to see:
   - Job status and logs
   - Test results and coverage
   - Security scan results
   - Published image tags

## Troubleshooting

### Workflow Fails on Test Job

```bash
# Run tests locally to debug
make test

# Or directly with Go
go test -v ./...
```

### Permission Denied Pushing to GHCR

- Ensure repository has Actions enabled
- Check that `GITHUB_TOKEN` has package write permissions
- For private repos, verify authentication settings

### Image Not Appearing in GHCR

- Check workflow logs for push step
- Verify the workflow completed successfully
- Package may take a few moments to appear after push

### Security Scan Failures

The security scan job runs on main branch only. To see results:
- Navigate to Security → Code scanning
- Review Trivy findings
- Critical CVEs may require base image updates

## Local Development

For local testing before pushing:

```bash
# Run tests
make test

# Build image locally
make docker-build

# Run container locally
make docker-run

# Access at http://localhost:8080
```

## Next Steps

1. **Commit and Push**: Commit the workflow file and push to trigger the first build
2. **Verify Build**: Check Actions tab for workflow status
3. **Test Image**: Pull and test the published image
4. **Configure CTF**: Deploy to your CTF infrastructure
5. **Monitor**: Watch for security scan results

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
