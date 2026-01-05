#!/usr/bin/env bash

source .env

while IFS= read -r dir; do
    echo "=== $dir ==="
    ./scripts/03_last_dirs.sh "$dir" $NUM_LAST_DIRS $NUM_LAST_ARCS
    echo
done
