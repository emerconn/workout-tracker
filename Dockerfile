# Build stage
FROM golang:1.23-alpine3.21 AS build
WORKDIR /app
COPY backend/ .
RUN go mod download
RUN apk add --no-cache upx
RUN CGO_ENABLED=0 GOOS=linux go build -o main .
RUN upx --best --lzma main

# Debug image
FROM alpine:3.21 AS debug
WORKDIR /app
COPY --from=build /app/main .
RUN addgroup -g 65532 nonroot && adduser -DHs /sbin/nologin -u 65532 -G nonroot nonroot
RUN chown nonroot:nonroot /app/main
USER nonroot:nonroot
EXPOSE 8080
ENV IS_CONTAINER=true
CMD ["./main"]

# Production image
FROM gcr.io/distroless/static-debian12 AS slim
WORKDIR /app
COPY --from=build /app/main .
USER nonroot:nonroot
EXPOSE 8080
ENV IS_CONTAINER=true
CMD ["./main"]
