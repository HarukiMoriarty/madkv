#!/bin/bash

# Read the number of clients from the command line
SERVER_ADDR=$1
TEST_CASE=$2

# for test case 1/2, run single thread with trace: test_case_{case_number}_single.trace
if [ $TEST_CASE -eq 1 ] || [ $TEST_CASE -eq 2 ]; then
	cat traces/test_case_${TEST_CASE}_single.trace | just p1::benchmark ${SERVER_ADDR} &
fi

# for test case 3/4, run 3 threads with trace: test_case_3_client{num}.trace
if [ $TEST_CASE -eq 3 ] || [ $TEST_CASE -eq 4 ]; then
	cat traces/test_case_${TEST_CASE}_client1.trace | just p1::benchmark ${SERVER_ADDR} &
	cat traces/test_case_${TEST_CASE}_client2.trace | just p1::benchmark ${SERVER_ADDR} &
	cat traces/test_case_${TEST_CASE}_client3.trace | just p1::benchmark ${SERVER_ADDR} &
fi

if [ $TEST_CASE -eq 5 ]; then
	cat traces/test_case_${TEST_CASE}_client1.trace | just p1::benchmark ${SERVER_ADDR} &
	cat traces/test_case_${TEST_CASE}_client2.trace | just p1::benchmark ${SERVER_ADDR} &
	cat traces/test_case_${TEST_CASE}_client3.trace | just p1::benchmark ${SERVER_ADDR} &
	cat traces/test_case_${TEST_CASE}_client4.trace | just p1::benchmark ${SERVER_ADDR} &
fi