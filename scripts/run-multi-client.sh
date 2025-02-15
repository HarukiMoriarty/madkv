#!/bin/bash

# Read the number of clients from the command line
SERVER_ADDR=$1
NUM_CLIENTS=$2

# Run the client concurrently
for i in $(seq 1 $NUM_CLIENTS); do
  cat traces/trace-1k-$i | just p1::benchmark ${SERVER_ADDR} &
done
