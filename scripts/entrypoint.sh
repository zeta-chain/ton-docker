#!/bin/bash

# Node/Genesis vars
export GENESIS="true"
export NAME="genesis"
export CUSTOM_PARAMETERS="--state-ttl 315360000 --archive-ttl 315360000"
export ENABLE_FILE_HTTP_SERVER=false
export EXTERNAL_IP=127.0.0.1

# RPC vars
export TON_API_HTTP_PORT=8081
export LITESERVER_CONFIG=/var/ton-work/db/localhost.global.config.json
export PARALLEL_REQUESTS_PER_LITESERVER=10
export TON_API_LOGS_LEVEL=INFO
export CDLL_PATH=/usr/local/bin/libtonlibjson.so

# RUN SIDECAR ================================================
sidecar &

# RUN NODE ===================================================
# Start the node script in background and capture all output
# https://github.com/neodix42/mylocalton-docker/blob/2610f20c391d3d0750760ae07454ed75109e4644/docker/scripts/start-node.sh
/scripts/start-node.sh &

# RUN HTTP RPC ================================================

# rpc should be started only after list-server is ready
query_lite_server() {
    # t = timeout seconds; c = command
	lite-client -C $LITESERVER_CONFIG -t 3 -c "$@"
}

while ! query_lite_server last; do
    echo "[entrypoint] waiting for lite server to be ready..."
    sleep 2
done

# Run RPC
ton-http-api \
  --port $TON_API_HTTP_PORT \
  --liteserver-config $LITESERVER_CONFIG \
  --parallel-requests-per-liteserver $PARALLEL_REQUESTS_PER_LITESERVER \
  --cdll-path $CDLL_PATH \
  --logs-level $TON_API_LOGS_LEVEL \
  --logs-jsonify &

# Wait for all processes to finish
wait -n
