FROM golang:1.22-alpine AS build_base

RUN apk add --no-cache git vips-dev gcc musl-dev

# Set the Current Working Directory inside the container
WORKDIR /tmp/app-code

# Populate the module cache based on the go.{mod,sum} files.
COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

# Build the Go app
RUN CC=gcc CGO_ENABLED=1 GOOS=linux go build -o ./out/api .

# Start fresh from a smaller image
FROM alpine:latest
RUN apk add --update --no-cache --repository https://dl-3.alpinelinux.org/alpine/edge/testing/ ca-certificates vips-dev

COPY --from=build_base /tmp/app-code/out/api /cmd/api

# Run the binary program produced by `go install`
EXPOSE 8080
CMD ["/cmd/api"]