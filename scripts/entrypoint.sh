#!/bin/bash

# Run JAR
java -jar my-local-ton.jar with-validators-1 nogui debug &

# Run sidecar
./sidecar &

# Wait for both processes to finish
wait -n
