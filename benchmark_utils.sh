#!/bin/bash

declare -A RESULTS

run_qemu() {
    local success_string="$1"
    local system="$2"
    local key="$3"
    local path="$4"
    local output

    if [[ "$system" == "false" ]]; then
        if ! output=$(qemu-riscv64 -plugin /libinsn.so "$path" 2>&1); then
            echo "ERROR: qemu-riscv64 failed for: $path" >&2
            exit 1
        fi
    else
        # Include OpenSBI BIOS (-bios default instead of -bios none) such that a shutdown function is present for improved benchmarking.
        if ! output=$(qemu-system-riscv64 -d plugin -machine virt -m 1024M -plugin /libinsn.so -kernel "$path" -nographic 2>&1); then
            echo "ERROR: qemu-system-riscv64 failed for: $path" >&2
            exit 1
        fi
    fi

    if ! echo "$output" | grep -q "$success_string"; then
        echo "ERROR: '$success_string' not found in output for: $path" >&2
        exit 1
    fi

    local insns
    if ! insns=$(echo "$output" | grep -oP 'total insns: \K[0-9]+'); then
        echo "ERROR: Could not extract instruction count from output for: $path" >&2
        exit 1
    fi

    RESULTS["$key"]=$insns
}

results_to_json() {
    # Generate JSON output
    local json='{}'
    for key in "${!RESULTS[@]}"; do
        json=$(echo "$json" | jq --arg key "$key" --argjson val "${RESULTS[$key]}" '. + {($key): $val}')
    done

    echo "$json" | jq '.'
}

