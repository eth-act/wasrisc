#!/bin/bash

set -e

./go_benchmark.sh
./rust_benchmark.sh

./aggregator.sh stateless.json reva-client-eth.json > report.md

# That's not part of report - just run to make sure it builds and executes without error
# ./go_benchmark_aarch64.sh

