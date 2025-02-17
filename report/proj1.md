# CS 739 MadKV Project 1

**Group members**: Qianliang Wu `qwu293@wisc.edu`, Zhenghong Yu `zyu379@wisc.edu`

## Design Walkthrough

### Client Layer

The client component is responsible for establishing and maintaining communication with the server's gateway via remote procedure calls (RPC). Upon startup, the client initializes a session that encapsulates both the transmission (tx) and reception (rx) channels used for command exchange. The session acts as an abstraction layer that enables the client to construct multi-operation commands and reliably transmit them to the server-side executor. Furthermore, the session provides mechanisms to handle retries and error notifications, ensuring robust interaction in the presence of transient failures.

### Server Architecture

The server is architected as a collection of modular components that collaborate to process and execute key-value (KV) operations. These components include the Gateway, Executor, Lock Manager, and Database. Each module is designed with clear responsibilities and well-defined interfaces, facilitating scalability and ease of maintenance.

#### Gateway

The gateway serves as the initial contact point for all incoming RPC requests. Its primary responsibility is to establish a connection with clients and to forward the resultant data stream to the executor component. By decoupling connection management from command execution, the gateway ensures that the system can efficiently handle a high volume of concurrent client connections.

#### Executor

Upon receiving a forwarded connection from the gateway, the executor spawns dedicated worker threads to manage client-specific command streams. Each worker thread listens for incoming KV operations and is responsible for orchestrating the execution pipeline. This pipeline involves calculating the read and write sets for each command, interacting with the lock manager to acquire the necessary locks, executing the operations against the underlying database, and subsequently releasing the locks. The executor also consolidates the results of the executed operations and transmits the final response back to the client. This modular approach allows for fine-grained control over concurrency and fault tolerance during command execution.

#### Lock Manager

The lock manager enforces concurrency control by implementing a hybrid locking mechanism that supports both shared and exclusive locks. When a worker thread requests locks for a given command, the lock manager examines the existing lock state and determines whether the command can be granted immediate access or must wait due to conflicts. In cases of conflict, younger transactions (i.e., those with higher command IDs) may be aborted to favor older transactions, thereby ensuring serializability and minimizing potential deadlocks. Once a command completes execution or is aborted, the lock manager is responsible for releasing the held locks and promoting waiting commands if applicable.

#### Database

The database module encapsulates the core key-value store functionality. It is designed to execute a variety of operations (e.g., PUT, GET, SWAP, DELETE, SCAN) with high efficiency. Notably, the database operates independently of the locking mechanism; it assumes that the executor has already coordinated lock acquisition. This separation of concerns simplifies the database's implementation and enhances overall system performance.

## Self-provided Testcases

<u>Found the following testcase results:</u> 1, 2, 3, 4, 5

### Explanations

*FIXME: add your explanations of each testcase*

## Fuzz Testing

<u>Parsed the following fuzz testing results:</u>

num_clis | conflict | outcome
:-: | :-: | :-:
1 | no | PASSED
3 | no | PASSED
3 | yes | PASSED

### Comments

*FIXME: add your comments on fuzz testing*

## YCSB Benchmarking

<u>Single-client throughput/latency across workloads:</u>

![single-cli](plots/ycsb-single-cli.png)

<u>Agg. throughput trend vs. number of clients:</u>

![tput-trend](plots/ycsb-tput-trend.png)

<u>Avg. & P99 latency trend vs. number of clients:</u>

![lats-trend](plots/ycsb-lats-trend.png)

### Comments

*FIXME: add your discussions of benchmarking results*

## Additional Discussion

*OPTIONAL: add extra discussions if applicable*

