#!/bin/bash

node_command="java -jar my-local-ton.jar with-validators-1 nogui debug"
sidecar_command="./sidecar"

timeout_seconds=300
poll_interval=10

status_url="http://localhost:8000/status"

start_processes() {
    echo "Starting node..."
    $node_command &
    node_pid=$!

    echo "Starting sidecar..."
    $sidecar_command &
    sidecar_pid=$!
}

check_status() {
    response=$(curl -s -w "\n%{http_code}" $status_url)
    body=$(echo "$response" | head -n 1)
    http_status=$(echo "$response" | tail -n 1)

    if [ "$http_status" == "200" ]; then
        echo "Pass: $body"
        return 0
    else
        echo "Waiting: $body"
        return 1
    fi
}

shutdown_processes() {
    echo "Shutting down node (PID: $node_pid)..."
    kill -SIGTERM $node_pid

    echo "Shutting down sidecar (PID: $sidecar_pid)..."
    kill -SIGTERM $sidecar_pid

    wait $node_pid
    wait $sidecar_pid

    echo "Node and sidecar shut down successfully."
}

# Handling script termination gracefully
trap shutdown_processes SIGTERM SIGINT

start_processes

echo "Checking $status_url (timeout: $timeout_seconds seconds)"

elapsed=0
while [ $elapsed -lt $timeout_seconds ]; do
    if check_status; then
        shutdown_processes
        exit 0
    fi

    sleep $poll_interval
    elapsed=$((elapsed + poll_interval))
done

echo "FAIL. Timeout reached ($timeout_seconds seconds)."
shutdown_processes
exit 1