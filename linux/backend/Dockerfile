FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git gcc musl-dev
WORKDIR /src
COPY go.mod ./
COPY . .
RUN go mod tidy && go mod download
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-s -w" -o /rakshak ./cmd/rakshak

FROM alpine:3.20
RUN apk add --no-cache ca-certificates wget curl bind-tools
COPY --from=builder /rakshak /rakshak
EXPOSE 8080
ENTRYPOINT ["/rakshak"]
CMD ["serve"]
