# Build a sidecar
FROM golang:1.20 AS go-builder
WORKDIR /opt/sidecar
COPY ./sidecar/ .
RUN go build -o /opt/sidecar/sidecar main.go

FROM ubuntu:24.04 AS ton-node

ARG WORKDIR="/opt/my-local-ton"

# Install dependencies && drop apt cache
# (including ton-http-api)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless curl jq vim lsb-release libatomic1 \
    python3 python3-pip python3-dev gcc && \
    pip3 install --break-system-packages --user ton-http-api && \
    apt-get remove -y python3-dev gcc && apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY scripts/download-jar.sh $WORKDIR/
COPY scripts/entrypoint.sh $WORKDIR/
COPY scripts/genesis.sh $WORKDIR/

COPY --from=go-builder /opt/sidecar $WORKDIR/

WORKDIR $WORKDIR

RUN ./download-jar.sh

# Ensure whether the build is working
RUN chmod +x entrypoint.sh \
    && chmod +x sidecar \
    && chmod +x genesis.sh \
    && java -jar my-local-ton.jar debug nogui test-binaries;

# Warmup the state
RUN ./genesis.sh

# Lite Client
EXPOSE 4443

# Sidecar
EXPOSE 8000

# HTTP RPC API
EXPOSE 8081

ENTRYPOINT ["/opt/my-local-ton/entrypoint.sh"]
