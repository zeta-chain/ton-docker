#!/bin/bash

# Start node
export GENESIS="true"
export NAME="genesis"
export CUSTOM_PARAMETERS="--state-ttl 315360000 --archive-ttl 315360000"
export ENABLE_FILE_HTTP_SERVER=false
export EXTERNAL_IP=127.0.0.1

/scripts/start-node.sh &

# HTTP RPC
export TON_API_HTTP_PORT=8081
export TON_API_LOGS_JSONIFY=true
export TON_API_LOGS_LEVEL=info
export LITESERVER_CONFIG=/var/ton-work/db/localhost.global.config.json

ton-http-api &

# Run sidecar
# TODO
# ./sidecar &

# Wait for all processes to finish
wait -n
