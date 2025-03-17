#!/bin/bash
trap "kill 0" EXIT

# Define trace file names
TRACE_BEFORE_KILL="traces/p2/trace_before_kill.txt"
TRACE_AFTER_KILL="traces/p2/trace_after_kill.txt"
TRACE_AFTER_RECOVERY="traces/p2/trace_after_recovery.txt"

# Create trace files
cat > $TRACE_BEFORE_KILL << EOF
PUT key00000 value0
PUT key00001 value1
PUT key00002 value2
PUT key00003 value3
PUT key00004 value4
PUT key00005 value5
PUT key00006 value6
PUT key00007 value7
PUT key00008 value8
PUT key00009 value9
PUT key00010 value10
PUT key00011 value11
PUT key00012 value12
PUT key00013 value13
PUT key00014 value14
SWAP key00000 value0_updated
SWAP key00002 value2_updated
SWAP key00005 value5_updated
SWAP key00008 value8_updated
SWAP key00010 value10_updated
SWAP key00013 value13_updated
GET key00000
GET key00003
GET key00005
GET key00008
GET key00010
GET key00013
SCAN key00000 key00004
SCAN key00005 key00009
SCAN key00010 key00014
SCAN key00000 key00014
SCAN key00003 key00011
STOP
EOF

cat > $TRACE_AFTER_KILL << EOF
GET key00000
GET key00002
GET key00004
GET key00010
GET key00012
GET key00014
SCAN key00000 key00004
SCAN key00010 key00014
GET key00005
GET key00007
GET key00009
SCAN key00004 key00006
SCAN key00008 key00011
SCAN key00000 key00014
STOP
EOF

cat > $TRACE_AFTER_RECOVERY << EOF
GET key00005
GET key00006
GET key00007
GET key00008
GET key00009
SCAN key00005 key00009
SCAN key00000 key00014
STOP
EOF

echo "=== Starting Partitioned Cluster Test ==="

# Start the manager
pkill -f "Distributed-KV-Store/target/release/manager"
echo "Starting manager..."
just p2::manager 3666 127.0.0.1:3777,127.0.0.1:3778,127.0.0.1:3779 key=15 &
MANAGER_PID=$!
sleep 3  # Give manager time to start

# Start the servers
echo "Starting server partitions..."
just p2::service s0 &
SERVER0_PID=$!
sleep 3  # Give servers time to start
just p2::service s1 &
SERVER1_PID=$!
sleep 3  # Give servers time to start
just p2::service s2 &
SERVER2_PID=$!
sleep 3  # Give servers time to start

# Run the first trace (before kill)
echo "=== Running trace before kill ==="
cat $TRACE_BEFORE_KILL | just p2::benchmark 127.0.0.1:3666 fuzz
echo "First trace completed"

# Kill server 1
echo "=== Killing server 1 ==="
kill $SERVER1_PID
kill -9 $(lsof -t -i:3778)
rm -rf data/1/db
sleep 3  # Give time for the server to shut down

# Run the second trace (after kill)
echo "=== Running trace after kill ==="
timeout 10s just p2::benchmark 127.0.0.1:3666 fuzz < $TRACE_AFTER_KILL
echo "Second trace completed"

# Restart server 1
echo "=== Restarting server 1 ==="
just p2::service s1 &
SERVER1_PID=$!
sleep 3  # Give server time to restart and recover

# Run the third trace (after recovery)
echo "=== Running trace after recovery ==="
cat $TRACE_AFTER_RECOVERY | just p2::benchmark 127.0.0.1:3666 fuzz
echo "Third trace completed"

# Clean up
echo "=== Cleaning up ==="
kill $SERVER0_PID $SERVER1_PID $SERVER2_PID $MANAGER_PID
rm $TRACE_BEFORE_KILL $TRACE_AFTER_KILL $TRACE_AFTER_RECOVERY

echo "=== Test completed ==="
exit 0
