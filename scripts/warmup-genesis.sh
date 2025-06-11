#!/bin/bash

# This scripts runs during docker image build to populate the state

export GENESIS="true"
export NAME="genesis"
export CUSTOM_PARAMETERS="--state-ttl 315360000 --archive-ttl 315360000"
export ENABLE_FILE_HTTP_SERVER=false
export EXTERNAL_IP=127.0.0.1

# Generate 1 new block per second
export NEXT_BLOCK_GENERATION_DELAY=1

# Validator set is valid for 30 seconds
export ORIGINAL_VALIDATOR_SET_VALID_FOR=30

echo "Starting genesis warmup. It should take 5 minutes approx."

# Create a temporary file for logging
LOG_FILE=$(mktemp)
echo "Logging to: $LOG_FILE"

# Start the node script in background and capture all output
# https://github.com/neodix42/mylocalton-docker/blob/e6c24af03cc1b6620c1a89c6dd117ddaab5aa859/docker/scripts/start-node.sh
/scripts/start-node.sh > "$LOG_FILE" 2>&1 &
NODE_PID=$!

echo "Running start-node.sh with PID: $NODE_PID"

cleanup() {
    echo "Cleaning up..."
    if kill -0 "$NODE_PID" 2>/dev/null; then
        echo "Sending SIGTERM to process $NODE_PID"
        kill -TERM "$NODE_PID"
        
        # Wait for graceful shutdown (up to 30 seconds)
        for i in {1..30}; do
            if ! kill -0 "$NODE_PID" 2>/dev/null; then
                echo "Process terminated gracefully"
                break
            fi
            sleep 1
        done
        
        # Force kill if still running
        if kill -0 "$NODE_PID" 2>/dev/null; then
            echo "Process still running, sending SIGKILL"
            kill -KILL "$NODE_PID"
        fi
    fi
    
    # Clean up log file
    rm -f "$LOG_FILE"
}

# Set up signal handlers
trap cleanup EXIT INT TERM

SUCCESS_MESSAGE="finished post-genesis.sh"

# Monitor the log file for the target message
echo "Monitoring logs for '$SUCCESS_MESSAGE'..."
tail -f "$LOG_FILE" &
TAIL_PID=$!

# Wait for the target message in the logs
while true; do
    if ! kill -0 "$NODE_PID" 2>/dev/null; then
        echo "Process $NODE_PID has terminated unexpectedly"
        kill "$TAIL_PID" 2>/dev/null
        exit 1
    fi
    
    if grep -q "$SUCCESS_MESSAGE" "$LOG_FILE" 2>/dev/null; then
        echo "Found '$SUCCESS_MESSAGE' in logs!"
        kill "$TAIL_PID" 2>/dev/null
        break
    fi
    
    sleep 1
done

echo "Genesis warmup completed successfully!"