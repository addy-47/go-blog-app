FROM golang:1.23-alpine

WORKDIR /app

# Copy Go module files
COPY go.mod ./

# Download dependencies and clean up unused ones
RUN go mod tidy

# Copy the source code and static files
COPY . .

# Build the application
RUN go build -o main .

# Run the application
CMD ["./main"]