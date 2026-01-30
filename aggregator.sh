#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <file1.json> [file2.json ...]" >&2
    exit 1
fi

# Extract keys as a union from all files
keys=($(jq -s '[.[] | keys[]] | unique[]' -r "$@"))

# Print header
header="| Language |"
separator="| --- |"
for key in "${keys[@]}"; do
    header+=" $key |"
    separator+=" --- |"
done
echo "$header"
echo "$separator"

# Print rows
for file in "$@"; do
    row="| $(basename "$file" .json) |"
    for key in "${keys[@]}"; do
        value=$(jq -r --arg key "$key" 'if has($key) then .[$key] | tostring else "N/A" end' "$file")
        row+=" $value |"
    done
    echo "$row"
done

