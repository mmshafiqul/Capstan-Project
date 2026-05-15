FROM golang:1.24-alpine

WORKDIR /app

# Install gcc and build tools for CGO (required by go-sqlite3)
RUN apk add --no-cache gcc musl-dev sqlite-dev git

# Copy all Go files (so go mod tidy sees imports)
COPY go.mod ./
COPY main.go ./

# Now download dependencies
RUN go mod tidy

# Build the application with CGO enabled
ENV CGO_ENABLED=1
RUN go build -tags "libsqlite3" -o urlshortener main.go

# Expose port
EXPOSE 8000

# Run the binary
CMD ["./urlshortener"]
