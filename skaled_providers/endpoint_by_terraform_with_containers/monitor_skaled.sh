#!/bin/bash
set -x

PORT=$1
PORT=${PORT:-1234}

NUM_NODES="${NUM_NODES:-2}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

SGX_URL="https://35.161.69.138:1026"

for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
done

shopt -s lastpipe
set -o pipefail

set +x

while true
do

	clear

	echo $( date )

	I=0
	for IP in ${IPS[*]:0:13}
	do
		
		I=$((I+1))
		
		curl -s -m 7 -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $IP:$PORT | jq '.result' | xargs printf '%d' | BN=$(</dev/stdin) || continue
		#curl -s -m 5 -X POST --data '{"jsonrpc":"2.0","method":"debug_interfaceCall","params":["SkaleHost trace count drop_good"],"id":2}' $IP:1234 | jq '.result' | xargs echo | T1=$(</dev/stdin) || continue
		#curl -s -m 5 -X POST --data '{"jsonrpc":"2.0","method":"debug_interfaceCall","params":["SkaleHost trace count import_consensus_born"],"id":3}' $IP:1234 | jq '.result' | xargs echo | T2=$(</dev/stdin) || continue
		
		#TN=$(( $T1 + $T2 ))
		
		echo $I $BN $IP
	
	done
	
	sleep 3
	
	echo
	
done

cd "$ORIG_CWD"
