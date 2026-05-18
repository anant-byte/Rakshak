FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN go mod tidy && CGO_ENABLED=0 go build -o /log-collector .

FROM alpine:3.20
RUN apk add --no-cache docker-cli
COPY --from=builder /log-collector /log-collector
