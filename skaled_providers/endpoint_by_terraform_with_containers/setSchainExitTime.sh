#!/bin/bash

# params:
# NUM_NODES - number of hosts
# tf/output.json

export NUM_NODES="${NUM_NODES:-4}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

# read tf/output.json -> IPS, LONG_IPS
for i in $( seq 0 $(($NUM_NODES-1)) )
do
        IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
        if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
        LONG_IPS[$i]=${IPS[$i]}:1231
done

#input: $IP, $TS
HOST_SET () {
        ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****

        for J in {0..0}
        do
            sudo curl -X POST --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\":\"setSchainExitTime\", \"params\":{\"finishTime\":$TS}}" http://127.0.0.1:1$((J+2))34
        done

****
}

echo -- Sending request to hosts --
TS=$(( $(date -u +%s) + 100 ))
for IP in ${IPS[*]} #:0:11}
do
        IP=$IP TS=$TS HOST_SET&
done

wait

cd "$ORIG_CWD"
