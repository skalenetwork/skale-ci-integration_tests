#!/bin/bash
set -x

NUM_NODES="${NUM_NODES:-2}"
SKALED_RELEASE="${SKALED_RELEASE:-develop-latest}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

SGX_URL="https://35.161.69.138:1026"

for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
done

I=0
for IP in ${IPS[*]:0:13}
do
	
	I=$((I+1))

	for J in {0..0}
	do

	ssh ubuntu@$IP "sudo docker logs skale-ci-$I-$J" >${I}_${J}.txt

	done
	
done

cd "$ORIG_CWD"
