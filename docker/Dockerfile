ARG GO_VERSION=1.27

############################
# Stage 1: build
############################
FROM golang:${GO_VERSION}-alpine AS build

WORKDIR /src

# Dependency layer first so it is cached across source changes.
COPY app/go.mod ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY app/ ./

ARG VERSION=dev
# Static, stripped, reproducible binary: no libc needed at runtime.
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux \
    go build -trimpath \
      -ldflags="-s -w -X main.version=${VERSION}" \
      -o /out/server ./cmd/server

############################
# Stage 2: runtime
############################
FROM gcr.io/distroless/static-debian12:nonroot

ARG VERSION=dev
LABEL org.opencontainers.image.title="items-api" \
      org.opencontainers.image.description="Sample REST API for the platform onboarding case study" \
      org.opencontainers.image.version="${VERSION}"

COPY --from=build --chown=65532:65532 /out/server /server

# Explicit numeric UID so Kubernetes runAsNonRoot can verify it.
USER 65532:65532

EXPOSE 8080
ENTRYPOINT ["/server"]
