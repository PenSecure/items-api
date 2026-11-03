# Base images are pinned by digest, not just tag, so a build is reproducible
# and cannot silently pick up a different image. Dependabot keeps both
# digests current.

############################
# Stage 1: build
############################
FROM golang:1.27-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS build

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
FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab

ARG VERSION=dev
LABEL org.opencontainers.image.title="items-api" \
      org.opencontainers.image.description="Sample REST API for the platform onboarding case study" \
      org.opencontainers.image.version="${VERSION}"

COPY --from=build --chown=65532:65532 /out/server /server

# Explicit numeric UID so Kubernetes runAsNonRoot can verify it.
USER 65532:65532

EXPOSE 8080
ENTRYPOINT ["/server"]
