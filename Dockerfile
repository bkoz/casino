FROM golang:1.21-alpine AS builder

WORKDIR /build

# Copy go files
COPY main.go .
COPY go.mod .

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-s -w' -o casino-kiosk .

# Final stage - minimal image
FROM alpine:latest

# Add ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy only the compiled binary (no source code!)
COPY --from=builder /build/casino-kiosk .

# Create non-root user
RUN adduser -D -u 1000 casino
USER casino

# Expose port
EXPOSE 8080

# Environment
ENV PORT=8080

# Run the binary
CMD ["./casino-kiosk"]
