# Debug builder
FROM golang:1.23-alpine3.21 AS debug-build
WORKDIR /app
COPY backend/ .
RUN go mod download
RUN apk add --no-cache upx
RUN CGO_ENABLED=0 GOOS=linux go build -o main .
RUN upx --best --lzma main

# Prod builder
FROM golang:1.23-alpine3.21 AS slim-build
WORKDIR /app
COPY backend/ .
RUN go mod download
RUN apk add --no-cache upx
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .
RUN upx --best --lzma main

# Debug image
FROM alpine:3.21 AS debug
LABEL org.opencontainers.image.description="workout-tracker debug"
WORKDIR /app
COPY --from=debug-build /app/main .
RUN addgroup -g 65532 nonroot && adduser -DHs /sbin/nologin -u 65532 -G nonroot nonroot
RUN chown nonroot:nonroot /app/main
USER nonroot:nonroot
EXPOSE 8080
ENV IS_CONTAINER=true
CMD ["./main"]

# Production image
FROM gcr.io/distroless/static-debian12 AS slim
LABEL org.opencontainers.image.description="workout-tracker slim"
WORKDIR /app
COPY --from=slim-build /app/main .
USER nonroot:nonroot
EXPOSE 8080
ENV IS_CONTAINER=true
CMD ["./main"]
