# CS 739 MadKV Project 1

**Group members**: Qianliang Wu `qwu293@wisc.edu`, Zhenghong Yu `zyu379@wisc.edu`

## 1 Design Walkthrough

### 1.1 Code Structure

```bash
├── common/           # Shared utilities and types
│   ├── id.rs         # ID generation/management
│   ├── lib.rs        # Common library exports
│   └── session.rs    # Client session abstraction

├── rpc/              # RPC/Network communication layer
│   ├── proto/    
│   │   └── gateway.proto  # RPC service definitions
│   └── lib.rs       

├── server/           # Server implementation
│   └── src/
│       ├── database.rs     # Core KV store implementation
│       ├── executor.rs     # Command execution logic
│       ├── gateway.rs      # RPC service interface
│       ├── lock_manager.rs # Concurrency control
│       └── main.rs      

├── client/           # Terminal interaction 
│   └── src/
│       └── main.rs  

├── benchmark/        # Stdin/out interaction
    └── src/
        └── main.rs  
```

![System Architecture](plots/architecture.jpg)

### 1.2 Client

The client component establishes and maintains communication with the server's gateway via remote procedure calls (RPC). The client constructs multi-operation commands and reliably transmits them to the server-side executor. The client also handles retries and error notifications, ensuring robust interaction during transient failures.

### 1.3 Server

The server has a modular component collection that processes and executes KV commands. These components include the Gateway, Executor, Lock Manager, and Database.

#### 1.3.1 Gateway

The gateway serves as the initial contact point for all incoming RPC requests. It establishes a client connection and forwards the command result stream to the executor component. By decoupling connection management from command execution, the gateway ensures the system can efficiently handle a high volume of concurrent client connections.

#### 1.3.2 Executor

Upon receiving a forwarded connection from the gateway, the executor spawns dedicated worker threads to manage client-specific command streams. 

Each worker thread listens to incoming KV operations and executes the pipeline. This pipeline involves calculating each command's read and write sets, interacting with the lock manager to acquire the necessary locks, executing the operations against the underlying database, and releasing the locks. 

The executor also consolidates the results of the executed operations and transmits the final response back to the client. 

#### 1.3.3 Lock Manager

The lock manager controls concurrency by implementing a wound-wait locking mechanism. 

When a worker thread requests locks for a given command, the lock manager determines whether it can be granted immediate access or must wait due to conflicts. In cases of conflict, younger transactions (i.e., those with higher command IDs) may be aborted to favor older transactions, thereby ensuring serializability and avoiding deadlocks. 

Once a command completes execution or is aborted, the lock manager releases the corresponding locks and promotes waiting commands if applicable.

#### 1.3.4 Database

The database module has the core key-value store functionality. Currently, the database uses an in-memory B-tree as the data structure. Notably, the database operates independently of the locking mechanism; it assumes that the executor has already coordinated lock acquisition.

### 1.4 RPC protocol

Clients establish a bidirectional streaming connection with server using `ConnectExecutor`.

Client send `Command` to Server, which contains a list of operations (GET/PUT/SWAP/SCAN/DELETE), each operation has a name and arguments.

Server responds `CommandResult` to Client, which contains results of each operation, execution status (COMMITTED or ABORTED) and any possible error information.

## 2 Self-provided Testcases

<u>Found the following testcase results:</u> 1, 2, 3, 4, 5

The input of each testcase can be found in the directory `traces/`, and the output logs of server are in directory `measurements/tests/`.

### 2.1 Explanations

#### 2.1.1 Testcase 1

This trace demonstrates all core KV operations—`PUT`, `GET`, `SWAP`, `DELETE`, and `SCAN`—in a single-client setting.

The log confirms that the server correctly handles newly inserted keys versus missing ones (reporting `not_found` or `null`), how `SWAP` returns the old value while updating to a new one, and includes `SCAN` ranges that produce both a valid list of results and an empty set.

#### 2.1.2 Testcase 2

This single-client trace includes consecutive `DELETE`s on the same key (first `found`, then `not_found`), and a `SCAN` that returns more than one key before another `SCAN` yields nothing.

#### 2.1.3 Testcase 3

In this multi-client scenario, each client uses disjoint key prefixes (`C1_`, `C2_`, `C3_`) to avoid conflicts. The operations are similar to the single-client tests (covering `PUT`, `GET`, `SWAP`, `DELETE`, `SCAN`), and the results show that the server can properly handle the concurrency.

#### 2.1.4 Testcase 4

This multi-client test contains three clients all operating on the same key (`sharedKey`), causing overlaps in `PUT`, `SWAP`, and `DELETE` operations. From the log, we can see that the server provides concurrency and shows the cross-client interference: each client’s changes immediately affect the key’s value and are observable in subsequent GET or SCAN operations by any other client.

#### 2.1.5 Testcase 5

In testcase 5, four different clients repeatedly operate on the same key (sharedKey) with all operations. They attempt reads on missing keys, perform consecutive deletes, and execute scans both with and without matching entries. This ensures robust coverage of concurrency behaviors and correct propagation of each client’s modifications in a shared keyspace.

## 3 Fuzz Testing

<u>Parsed the following fuzz testing results:</u>

num_clis | conflict | outcome
:-: | :-: | :-:
1 | no | PASSED
3 | no | PASSED
3 | yes | PASSED

### 3.1 Comments

These fuzz tests examined the KV store with large numbers of randomly generated operations. The first single-client test confirmed basic correctness in a non-concurrent environment. In test two , the result showed the server can work well under concurrency. The fianl test running multi-clients with conflict operations validated that the server can maintain consistency among clients.

## 4 YCSB Benchmarking

<u>Single-client throughput/latency across workloads:</u>

![single-cli](plots/ycsb-single-cli.png)

<u>Agg. throughput trend vs. number of clients:</u>

![tput-trend](plots/ycsb-tput-trend.png)

<u>Avg. & P99 latency trend vs. number of clients:</u>

![lats-trend](plots/ycsb-lats-trend.png)

### 4.1 Comments

*FIXME: add your discussions of benchmarking results*

## 5 Additional Discussion

*OPTIONAL: add extra discussions if applicable*

