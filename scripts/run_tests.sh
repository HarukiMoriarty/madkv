#!/bin/bash
# run_tests.sh
# Usage: ./run_tests.sh <server_addr>
#
# For each test case, ensure that the server is freshly started on a separate machine using:
#    just p1::service 0.0.0.0:<port>
#
# Then run the client-side test as listed below.

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <server_addr>"
    exit 1
fi

SERVER_ADDR="$1"

# Pause function to let the user prepare a fresh server instance for each test case.
pause_for_server() {
    echo "------------------------------------------"
    echo "IMPORTANT: Please ensure you have restarted the server using:"
    echo "         just p1::service 0.0.0.0:<port>"
    echo "         on the server machine (fresh instance for this test)."
    read -p "Press Enter to continue with the next test..." dummy
    echo "------------------------------------------"
}

echo "-------------------"
echo "YCSB Tests: 1 client"
echo "-------------------"
# 1-client tests with different workloads.
for workload in a b c d e f; do
    echo "Running test: p1::bench 1 $workload $SERVER_ADDR"
    just p1::bench 1 "$workload" "$SERVER_ADDR"
    pause_for_server
done

echo ""
echo "---------------------------------"
echo "YCSB Tests: Multi-client: Workload 'a'"
echo "---------------------------------"
# Multi-client tests for workload "a" with various client counts.
for clients in 10 25 40 55 70 85; do
    echo "Running test: p1::bench $clients a $SERVER_ADDR"
    just p1::bench "$clients" a "$SERVER_ADDR"
    pause_for_server
done

echo ""
echo "---------------------------------"
echo "YCSB Tests: Multi-client: Workload 'c'"
echo "---------------------------------"
# Multi-client tests for workload "c".
for clients in 10 25 40 55 70 85; do
    echo "Running test: p1::bench $clients c $SERVER_ADDR"
    just p1::bench "$clients" c "$SERVER_ADDR"
    pause_for_server
done

echo ""
echo "---------------------------------"
echo "YCSB Tests: Multi-client: Workload 'e'"
echo "---------------------------------"
# Multi-client tests for workload "e".
for clients in 10 25 40 55 70 85; do
    echo "Running test: p1::bench $clients e $SERVER_ADDR"
    just p1::bench "$clients" e "$SERVER_ADDR"
    pause_for_server
done

echo "All tests completed."
