#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <partition_size> <partition_id> <replica_size> <replica_id>"
    echo "Example: $0 3 0 3 1"
    echo "  This will launch a server for partition 0, replica 1 in a system with 3 partitions and 3 replicas per partition"
    exit 1
fi

PARTITION_SIZE=$1
PARTITION_ID=$2
REPLICA_SIZE=$3
REPLICA_ID=$4

# Validate inputs
if ! [[ "$PARTITION_SIZE" =~ ^[0-9]+$ ]] || ! [[ "$PARTITION_ID" =~ ^[0-9]+$ ]] || ! [[ "$REPLICA_SIZE" =~ ^[0-9]+$ ]] || ! [[ "$REPLICA_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: All arguments must be non-negative integers"
    exit 1
fi

if [ "$PARTITION_ID" -ge "$PARTITION_SIZE" ]; then
    echo "Error: partition_id must be less than partition_size"
    exit 1
fi

if [ "$REPLICA_ID" -ge "$REPLICA_SIZE" ]; then
    echo "Error: replica_id must be less than replica_size"
    exit 1
fi

# Base ports
BASE_MANAGER_PORT=3666
BASE_API_PORT=3777
BASE_P2P_PORT=3707

# Calculate ports for this server
API_PORT=$((BASE_API_PORT + PARTITION_ID * REPLICA_SIZE + REPLICA_ID))

# Generate peer addresses for this server's replica group
PEERS=""
for i in $(seq 0 $((REPLICA_SIZE - 1))); do
    if [ "$i" -ne "$REPLICA_ID" ]; then
        PEER_PORT=$((BASE_P2P_PORT + PARTITION_ID * REPLICA_SIZE + i))
        if [ -z "$PEERS" ]; then
            PEERS="127.0.0.1:$PEER_PORT"
        else
            PEERS="$PEERS,127.0.0.1:$PEER_PORT"
        fi
    fi
done

# Calculate P2P port for this server
P2P_PORT=$((BASE_P2P_PORT + PARTITION_ID * REPLICA_SIZE + REPLICA_ID))

# Create backer path
BACKER_PATH="./data"

echo "Starting server with:"
echo "  Partition ID: $PARTITION_ID"
echo "  Replica ID: $REPLICA_ID"
echo "  API Port: $API_PORT"
echo "  P2P Port: $P2P_PORT"
echo "  Peers: $PEERS"
echo "  Backer Path: $BACKER_PATH"

# Run the server using the just recipe
just p3::server "$PARTITION_ID" "$REPLICA_ID" "127.0.0.1:$BASE_MANAGER_PORT" "$API_PORT" "$P2P_PORT" "$PEERS" "$BACKER_PATH"
