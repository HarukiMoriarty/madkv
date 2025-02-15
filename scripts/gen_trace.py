#!/usr/bin/env python3
import random
import string
import sys

NUM_COMMANDS = 50
OUTPUT_DIR = "traces/"
TRACE_FILE = "trace.txt"
# Define allowed characters for keys and values: ASCII letters and digits.
ALPHANUM = string.ascii_letters + string.digits

def random_alphanum(length=6):
    """Generate a random alphanumeric string of a given length."""
    return ''.join(random.choices(ALPHANUM, k=length))

def generate_trace(num_commands=10):
    """
    Generate a random trace of commands.
    Available commands are:
      - PUT <key> <value>
      - SWAP <key> <value>
      - GET <key>
      - DELETE <key>
      - SCAN <start_key> <end_key>
    The trace always ends with a STOP command.
    
    All keywords (commands) are case-sensitive, and keys/values
    are valid ASCII alphanumeric strings.
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
            # Generate two keys and ensure they are in lexicographical order.
            key1 = random_alphanum()
            key2 = random_alphanum()
            if key1 > key2:
                key1, key2 = key2, key1
            trace.append(f"SCAN {key1} {key2}")

    trace.append("STOP")
    return trace

def print_usage():
    print("Usage: {} <num_commands> <trace_file>".format(sys.argv[0]))
    print("  <num_commands>  : Number of commands to generate (excluding STOP)")
    print("  <trace_file>    : Output file name for the generated trace")

if __name__ == '__main__':
    # Check for two command-line arguments.
    if len(sys.argv) != 3:
        print_usage()
        sys.exit(1)
    
    try:
        num_commands = int(sys.argv[1])
    except ValueError:
        print("Error: <num_commands> must be an integer.")
        print_usage()
        sys.exit(1)
    
    trace_file = sys.argv[2]
    
    trace = generate_trace(num_commands)
    
    try:
        with open(trace_file, "w") as f:
            f.write("\n".join(trace))
        print(f"Trace successfully written to {trace_file}")
    except IOError as e:
        print(f"Error writing to file {trace_file}: {e}")
        sys.exit(1)
