#!/bin/bash

JAVA_ARGS="with-validators-1 nogui ton-http-api"

# Run JAR
java -jar my-local-ton.jar $JAVA_ARGS &

# Run sidecar
./sidecar &

# Wait for both processes to finish
wait -n
