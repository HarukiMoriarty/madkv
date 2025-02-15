set working-directory := '..'

# list project 1 just recipes
default:
    @just --list p1 --unsorted

# install extra dependencies of your KV code
deps:
    git submodule add https://github.com/HarukiMoriarty/Distributed-KV-Store.git

# build your executables in release mode
build:
    cargo build --release
    git submodule update --recursive --remote

# clean the build of your executables
clean:
    cargo clean --release

# generate random trace for testing
trace num_op="1000" file="trace-1k-1":
    python3 tracegen.py {{num_op}} {{file}}

# run your KV store server
server listen="0.0.0.0:3777":
    cargo run --release --manifest-path=Distributed-KV-Store/Cargo.toml --bin server -- --connect-addr {{listen}}

# run you KV store client in stdin/out interface mode
client server="127.0.0.1:3777":
    cargo run --release --manifest-path=Distributed-KV-Store/Cargo.toml --bin client -- --connect-addr {{server}}

# run you KV store client in stdin/out interface mode (with madkv format)
benchmark server="127.0.0.1:3777":
    cargo run --release --manifest-path=Distributed-KV-Store/Cargo.toml --bin benchmark -- --connect-addr {{server}}

# run your KV store testcase 1 client
test1 server="127.0.0.1:3777":
    cat traces/trace-1k-1 | just p1::benchmark {{server}} &

# run your KV store testcase 2 client
test2 server="127.0.0.1:3777":
    ./scripts/run-multi-client.sh {{server}} 2

# run your KV store testcase 3 client
test3 server="127.0.0.1:3777":
    ./scripts/run-multi-client.sh {{server}} 3


# run your KV store testcase 4 client(s)
test4 server="127.0.0.1:3777":
    ./scripts/run-multi-client.sh {{server}} 4

# run your KV store testcase 5 client(s)
test5 server="127.0.0.1:3777":
    ./scripts/run-multi-client.sh {{server}} 5

# kill all processes of your KV store system
kill:
    # FIXME: your kill commands here
    #        make sure that it kills all server, clients, and any extra helper
    #        processes of your system; redirecting both out & err to /dev/null
    #        is recommended
    #   TIP: commands such as 'pkill' may return non-zero exit code on success,
    #        which would by default abort the 'just' recipe early; prepend the
    #        command with a '-' sign to ignore its exit code
    pkill -f "server|benchmark"

# NOTE: feel free to add more recipes as you see fit...
#       also feel free to add extra parameters to the recipes as you see fit,
#       but don't change the existing parameters

# launch a long-running KV store service
service listen="0.0.0.0:3777":
    just p1::build
    just utils::build
    cargo run -p runner -r --bin service -- \
        --just-args p1::server "{{listen}}"

# ensure a subdir under 'tmp/' exists
tmpdir subdir:
    mkdir -p "/tmp/madkv-p1/{{subdir}}"

# run a student-provided testcase
testcase num server="127.0.0.1:3777": (tmpdir "tests")
    just p1::build
    just "p1::test{{num}}" "{{server}}" \
        | tee "/tmp/madkv-p1/tests/test{{num}}.log"
    just p1::kill

# run a fuzz testing scenario
fuzz nclis conflict="no" server="127.0.0.1:3777": (tmpdir "fuzz")
    just p1::build
    just utils::build
    cargo run -p runner -r --bin fuzzer -- \
        --num-clis "{{nclis}}" \
        {{ if conflict == "no" { "" } else { "--conflict" } }} \
        --just-args p1::benchmark "{{server}}" \
        | tee "/tmp/madkv-p1/fuzz/fuzz-{{nclis}}-{{conflict}}.log"
    just p1::kill

# run a YCSB benchmark workload
bench nclis wload server="127.0.0.1:3777": (tmpdir "bench")
    just p1::build
    just utils::build
    just utils::ycsb
    cargo run -p runner -r --bin bencher -- \
        --num-clis "{{nclis}}" \
        --workload "{{wload}}" \
        --just-args p1::benchmark "{{server}}" \
        | tee "/tmp/madkv-p1/bench/bench-{{nclis}}-{{wload}}.log"
    just p1::kill

# generate .md report template from existing results (wip)
report:
    python3 sumgen/proj1.py
