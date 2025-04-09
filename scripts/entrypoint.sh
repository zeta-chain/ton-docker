#!/bin/bash

# Check if RPC should be enabled
JAVA_ARGS="with-validators-1 nogui debug"
if [ "$ENABLE_RPC" = "true" ]; then
    echo "RPC is enabled"
    JAVA_ARGS="$JAVA_ARGS ton-http-api"
fi

# Run JAR
java -jar my-local-ton.jar $JAVA_ARGS &

# Run sidecar
./sidecar &

# Wait for both processes to finish
wait -n
