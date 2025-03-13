set working-directory := '..'

# list project 2 just recipes
default:
    @just --list p2 --unsorted

# install extra dependencies of your KV code
deps:
    git submodule add https://github.com/HarukiMoriarty/Distributed-KV-Store.git

# build your executables in release mode
build:
    git submodule update --recursive --remote --init
    cd Distributed-KV-Store
    cargo build --release

# clean the build of your executables
clean:
    cd Distributed-KV-Store
    cargo clean --release

# run your KV store manager
manager man_port="3666" servers="127.0.0.1:3777,127.0.0.1:3778,127.0.0.1:3779":
    cargo run --release --manifest-path=Distributed-KV-Store/Cargo.toml --bin manager -- --listen-addr 127.0.0.1:{{man_port}} --servers {{servers}} --tables key=10000000

# run your KV store server
server id="0" manager="127.0.0.1:3666" api_port="3777" backer_path="./data":
    cargo run --release --manifest-path=Distributed-KV-Store/Cargo.toml --bin server -- --node-id {{id}} --listen-addr 127.0.0.1:{{api_port}} --manager-addr {{manager}} --db-path {{backer_path}}/{{id}}/db --log-path {{backer_path}}/{{id}}/log --persistence --batch-size 100 --batch-timeout 1000

# run you KV store client in stdin/out interface mode
benchmark manager="127.0.0.1:3666":
    cargo run --manifest-path=Distributed-KV-Store/Cargo.toml --bin benchmark -- --connect-addr {{manager}}

# kill all processes of your KV store system
kill:
    # FIXME: your kill commands here
    #        make sure that it kills all server, clients, and any extra helper
    #        processes of your system; redirecting both out & err to /dev/null
    #        is recommended
    #   TIP: commands such as 'pkill' may return non-zero exit code on success,
    #        which would by default abort the 'just' recipe early; prepend the
    #        command with a '-' sign to ignore its exit code
    -pkill -f "Distributed-KV-Store/target/release/server"  > /dev/null 2>&1
    -pkill -f "Distributed-KV-Store/target/release/client"  > /dev/null 2>&1
    -pkill -f "Distributed-KV-Store/target/release/manager"  > /dev/null 2>&1
    -pkill -f "Distributed-KV-Store/target/release/benchmark"  > /dev/null 2>&1
    rm -rf data/*

# NOTE: feel free to add more recipes as you see fit...
#       also feel free to add extra parameters to the recipes as you see fit,
#       but don't change the existing parameters

python_run := if `which uv || true` != "" { "uv run" } else { "python3" }
tmpdir_prefix := "/tmp/madkv-p2"

# launch the KV service components on node (see README for conventions)
service node="s0" manager="127.0.0.1:3666" servers="127.0.0.1:3777,127.0.0.1:3778,127.0.0.1:3779" backer_prefix="./backer":
    just p2::build
    just utils::build
    cargo run -p runner -r --bin service -- \
        --server-just-args p2::server \
            $({{python_run}} justmod/xtract.py partid "{{node}}") \
            "{{manager}}" \
            $({{python_run}} justmod/xtract.py portof "{{servers}}" "{{node}}") \
            "{{backer_prefix}}.{{node}}" \
        --manager-just-args p2::manager \
            $({{python_run}} justmod/xtract.py portof "{{manager}}" "{{node}}") \
            "{{servers}}" \
        --node-id "{{node}}"

# ensure a subdir under 'tmp/' exists
tmpdir subdir:
    mkdir -p "{{tmpdir_prefix}}/{{subdir}}"

# run a fuzz testing scenario
fuzz nservers="1" crashing="no" manager="127.0.0.1:3666": (tmpdir "fuzz")
    just p2::build
    just utils::build
    cargo run -p runner -r --bin fuzzer -- \
        --num-clis 5 \
        --conflict \
        --client-just-args p2::benchmark "{{manager}}" \
        | tee "{{tmpdir_prefix}}/fuzz/fuzz-{{nservers}}-{{crashing}}.log"
    just p2::kill

# run a YCSB benchmark workload
bench nclis wload nservers="1" manager="127.0.0.1:3666": (tmpdir "bench")
    just p2::build
    just utils::build
    just utils::ycsb
    cargo run -p runner -r --bin bencher -- \
        --num-clis "{{nclis}}" \
        --workload "{{wload}}" \
        --client-just-args p2::benchmark "{{manager}}" \
        | tee "{{tmpdir_prefix}}/bench/bench-{{nclis}}-{{wload}}-{{nservers}}.log"
    just p2::kill

# generate .md report template from existing results (wip)
report:
    {{python_run}} sumgen/proj2.py
