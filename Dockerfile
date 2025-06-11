# Build a sidecar
FROM golang:1.20 AS go-builder
WORKDIR /opt/sidecar
COPY ./sidecar/ .
RUN go build -ldflags="-w -s" -o /opt/sidecar/sidecar main.go

# https://github.com/neodix42/mylocalton-docker/blob/main/Dockerfile
# https://github.com/neodix42/mylocalton-docker/blob/e6c24af03cc1b6620c1a89c6dd117ddaab5aa859/.github/workflows/docker.yml#L43
FROM ghcr.io/neodix42/mylocalton-docker:latest

# Warmup genesis to speed up startup time
COPY scripts/warmup-genesis.sh /scripts/
RUN chmod +x /scripts/warmup-genesis.sh && /scripts/warmup-genesis.sh

RUN apt-get update && apt install -y pip && \
    pip install ton-http-api && \
    apt remove -y python3-dev gcc && \
    apt autoremove -y && rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache

COPY --from=go-builder /opt/sidecar/sidecar /usr/local/bin/sidecar
COPY scripts/entrypoint.sh /scripts/

# Lite Server
EXPOSE 40004

# RPC (toncenter v2)
EXPOSE 8081

# Sidecar (healthcheck, faucet, ...)
EXPOSE 8000

ENTRYPOINT ["/scripts/entrypoint.sh"]

CMD [  ]
