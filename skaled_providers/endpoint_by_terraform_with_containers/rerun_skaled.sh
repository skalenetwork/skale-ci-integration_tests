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

echo -- Prepare nodes ---

I=0
for IP in ${IPS[*]:0:13}
do
	
	I=$((I+1))

	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****

	for J in {0..0}
	do

	sudo docker stop skale-ci-$I-\$J
	sudo docker rm skale-ci-$I-\$J
	
		sudo docker run -d --cap-add SYS_ADMIN --name=skale-ci-$I-\$J -v /home/ubuntu/skale_node_data:/skale_node_data -v /home/ubuntu/data_dir/\$J:/data_dir -p 1\$((2+J))31-1\$((2+J))39:1\$((2+J))31-1\$((2+J))39/tcp -e DATA_DIR=/data_dir -e catchupIntervalMs=1000000000 -i -t --stop-timeout 40 skalenetwork/schain:$SKALED_RELEASE --http-port 1\$((2+J))34 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 3 --web3-trace --enable-debug-behavior-apis --aa no
	
	done
	
	****

done

cd "$ORIG_CWD"
