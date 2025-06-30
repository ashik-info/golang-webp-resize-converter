# --- Stage 1: Build the Go app with CGO and libwebp support ---
FROM golang:1.22-bullseye as builder

# Install libwebp for nativewebp bindings
RUN apt-get update && apt-get install -y libwebp-dev

WORKDIR /app

# Cache Go dependencies first
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Enable CGO
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=amd64

# Build the Go app
RUN go build -o app main.go

# --- Stage 2: Minimal runtime image ---
FROM debian:bookworm-slim

# Install only runtime libwebp
RUN apt-get update && apt-get install -y --no-install-recommends \
    libwebp-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/app .

# Create directory to store generated WebP files
RUN mkdir -p /app/files

EXPOSE 3000

CMD ["./app"]
