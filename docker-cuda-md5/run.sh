#!/bin/bash

set -e

input="hashes.txt"
i=0
while IFS= read -r line; do
    if [[ $((i % $XDCS_AGENT_COUNT)) = $XDCS_AGENT_ID ]]; then
        echo ===== Cracking "$line"
        ./md5-cracker/md5_gpu "$line" | tee -a output.txt
    fi
    i=$((i + 1))
done < "$input"
