#!/usr/bin/env python3
import random
import string
import sys
import os

OUTPUT_DIR = "traces/"
os.makedirs(OUTPUT_DIR, exist_ok=True)

ALPHANUM = string.ascii_letters + string.digits

def random_alphanum(length=6):
    """Generate a random alphanumeric string of a given length."""
    return ''.join(random.choices(ALPHANUM, k=length))

def generate_single_client_trace(num_commands=10):
    """
    Generate a random trace for a single client.
    Available commands: PUT, SWAP, GET, DELETE, SCAN.
    The trace always ends with a STOP command.
    """
    commands = ["PUT", "SWAP", "GET", "DELETE", "SCAN"]
    trace = []
    for _ in range(num_commands):
        cmd = random.choice(commands)
        if cmd == "PUT":
            key = random_alphanum()
            value = random_alphanum()
            trace.append(f"PUT {key} {value}")
        elif cmd == "SWAP":
            key = random_alphanum()
            value = random_alphanum()
            trace.append(f"SWAP {key} {value}")
        elif cmd == "GET":
            key = random_alphanum()
            trace.append(f"GET {key}")
        elif cmd == "DELETE":
            key = random_alphanum()
            trace.append(f"DELETE {key}")
        elif cmd == "SCAN":
            key1 = random_alphanum()
            key2 = random_alphanum()
            if key1 > key2:
                key1, key2 = key2, key1
            trace.append(f"SCAN {key1} {key2}")
    trace.append("STOP")
    return trace

def generate_multi_client_traces(num_clients=2, num_commands=10, interfering=False):
    """
    Generate traces for multiple clients.
    Returns a dict {client_id: trace_list}.
    
    - In non-interfering mode, each client's keys are prefixed (e.g. C1_).
    - In interfering mode, all clients use the same shared keys.
    """
    traces = {}
    if interfering:
        # Pre-generate a list of shared keys (one per command)
        shared_keys = [random_alphanum() for _ in range(num_commands)]
        for client in range(1, num_clients+1):
            trace = []
            for i in range(num_commands):
                cmd = random.choice(["PUT", "SWAP", "GET", "DELETE", "SCAN"])
                if cmd in ["PUT", "SWAP", "GET", "DELETE"]:
                    key = shared_keys[i]
                    if cmd in ["PUT", "SWAP"]:
                        value = random_alphanum()
                        trace.append(f"{cmd} {key} {value}")
                    else:
                        trace.append(f"{cmd} {key}")
                elif cmd == "SCAN":
                    # For SCAN, pick two shared keys (using consecutive indices)
                    key1 = shared_keys[i]
                    key2 = shared_keys[(i+1) % num_commands]
                    if key1 > key2:
                        key1, key2 = key2, key1
                    trace.append(f"SCAN {key1} {key2}")
            trace.append("STOP")
            traces[client] = trace
    else:
        # Non-interfering: each client gets its own keyspace via prefix.
        for client in range(1, num_clients+1):
            trace = []
            for _ in range(num_commands):
                cmd = random.choice(["PUT", "SWAP", "GET", "DELETE", "SCAN"])
                if cmd in ["PUT", "SWAP", "GET", "DELETE"]:
                    key = f"C{client}_" + random_alphanum()
                    if cmd in ["PUT", "SWAP"]:
                        value = random_alphanum()
                        trace.append(f"{cmd} {key} {value}")
                    else:
                        trace.append(f"{cmd} {key}")
                elif cmd == "SCAN":
                    key1 = f"C{client}_" + random_alphanum()
                    key2 = f"C{client}_" + random_alphanum()
                    if key1 > key2:
                        key1, key2 = key2, key1
                    trace.append(f"SCAN {key1} {key2}")
            trace.append("STOP")
            traces[client] = trace
    return traces

def write_trace_to_file(trace, filename):
    file_path = os.path.join(OUTPUT_DIR, filename)
    try:
        with open(file_path, "w") as f:
            f.write("\n".join(trace))
        print(f"Trace successfully written to {file_path}")
    except IOError as e:
        print(f"Error writing to file {file_path}: {e}")

def print_usage():
    print("Usage:")
    print("  For single client: {} single <num_commands> <trace_file>".format(sys.argv[0]))
    print("  For multi-client: {} multi <non_int|int> <num_commands> <num_clients> <trace_file_prefix>".format(sys.argv[0]))
    print("    non_int: non-interfering, int: interfering")

if __name__ == '__main__':
    # When no command-line arguments are provided, generate our 5 test cases.
    if len(sys.argv) == 1:
        print("No arguments provided. Generating 5 test cases as required.")

        # Test Case 1: Single client (10 commands)
        trace1 = generate_single_client_trace(num_commands=10)
        write_trace_to_file(trace1, "test_case_1_single.trace")

        # Test Case 2: Single client (12 commands)
        trace2 = generate_single_client_trace(num_commands=12)
        write_trace_to_file(trace2, "test_case_2_single.trace")

        # Test Case 3: Multi-client non-conflicting (3 clients, 6 commands each)
        multi_traces = generate_multi_client_traces(num_clients=3, num_commands=6, interfering=False)
        for client, trace in multi_traces.items():
            write_trace_to_file(trace, f"test_case_3_client{client}.trace")

        # Test Case 4: Multi-client interfering (3 clients, 6 commands each)
        multi_traces = generate_multi_client_traces(num_clients=3, num_commands=6, interfering=True)
        for client, trace in multi_traces.items():
            write_trace_to_file(trace, f"test_case_4_client{client}.trace")

        # Test Case 5: Multi-client interfering (4 clients, 8 commands each)
        multi_traces = generate_multi_client_traces(num_clients=4, num_commands=8, interfering=True)
        for client, trace in multi_traces.items():
            write_trace_to_file(trace, f"test_case_5_client{client}.trace")

        sys.exit(0)
    else:
        # Custom generation via command-line arguments.
        if sys.argv[1] == "single":
            if len(sys.argv) != 4:
                print_usage()
                sys.exit(1)
            try:
                num_commands = int(sys.argv[2])
            except ValueError:
                print("Error: <num_commands> must be an integer.")
                sys.exit(1)
            filename = sys.argv[3]
            trace = generate_single_client_trace(num_commands)
            write_trace_to_file(trace, filename)
        elif sys.argv[1] == "multi":
            if len(sys.argv) != 6:
                print_usage()
                sys.exit(1)
            mode = sys.argv[2]
            try:
                num_commands = int(sys.argv[3])
                num_clients = int(sys.argv[4])
            except ValueError:
                print("Error: <num_commands> and <num_clients> must be integers.")
                sys.exit(1)
            prefix = sys.argv[5]
            interfering = True if mode == "int" else False
            multi_traces = generate_multi_client_traces(num_clients, num_commands, interfering)
            for client, trace in multi_traces.items():
                write_trace_to_file(trace, f"{prefix}_client{client}.trace")
        else:
            print_usage()
            sys.exit(1)
