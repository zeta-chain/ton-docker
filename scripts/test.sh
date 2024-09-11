#!/bin/bash

# Sometimes my-local-ton is flaky on genesis step and we want to make sure that this very build works
# i.e. the node is running and the faucet is created.

if [ -z "$1" ]; then
    echo "Error: No image name provided."
    echo "Usage: $0 <image_name>"
    exit 1
fi

IMAGE_NAME=$1
CONTAINER_NAME="ton-test"
STATUS_URL="http://localhost:8000/status"
TIMEOUT=300  # 5 minutes
INTERVAL=10  # check every 10 seconds
START_TIME=$(date +%s)

cleanup() {
    echo "Stopping the container..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
}

echo "Starting container..."
docker run -d --rm --name $CONTAINER_NAME -p 8000:8000 $IMAGE_NAME

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    # Exit loop if timeout is reached
    if [ $ELAPSED_TIME -ge $TIMEOUT ]; then
        echo "Timeout exceeded. The service didn't become ready."
        cleanup
        exit 1
    fi

    # Check if the service is ready
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $STATUS_URL)
    BODY=$(curl -s $STATUS_URL)

    if [[ "$RESPONSE" == "200" && "$BODY" == *"OK"* ]]; then
        echo "Pass"
        cleanup
        exit 0
    fi

    sleep $INTERVAL
    echo "Waiting for the service to become ready... $BODY"
done