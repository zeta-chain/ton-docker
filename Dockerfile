# Build a sidecar
FROM golang:1.20 AS go-builder
WORKDIR /opt/sidecar
COPY ./sidecar/ .
RUN go build -o /opt/sidecar/sidecar main.go

FROM openjdk:24-slim AS ton-node

ARG WORKDIR="/opt/my-local-ton"

# Install dependencies && drop apt cache
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      curl jq vim lsb-release \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/my-local-ton.jar $WORKDIR/
COPY scripts/entrypoint.sh $WORKDIR/

COPY --from=go-builder /opt/sidecar $WORKDIR/

WORKDIR $WORKDIR

# Ensure whether the build is working
RUN chmod +x entrypoint.sh \
    && chmod +x sidecar \
    && java -jar my-local-ton.jar debug nogui test-binaries;

# Lite Client
EXPOSE 4443

# Sidecar
EXPOSE 8000

ENTRYPOINT ["/opt/my-local-ton/entrypoint.sh"]
