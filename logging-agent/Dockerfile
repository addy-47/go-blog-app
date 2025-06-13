FROM golang:1.22-alpine
WORKDIR /app
COPY logging-agent /app/logging-agent
RUN chmod +x /app/logging-agent
CMD ["/app/logging-agent"]
