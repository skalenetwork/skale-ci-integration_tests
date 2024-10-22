#!/bin/bash
set -x

NUM_NODES="${NUM_NODES:-2}"
SKALED_RELEASE="${SKALED_RELEASE:-develop-latest}"

REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_HOME="/home/$REMOTE_USER"
if [ "$REMOTE_USER" = "root" ]
then
  REMOTE_HOME="/root"
fi

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

export SGX_URL="${SGX_URL:-https://167.235.155.228}"

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

	ssh -o "StrictHostKeyChecking no" $REMOTE_USER@$IP <<- **** &

    for J in {0..0}
    do

	sudo docker stop skale-ci-\$J
	sudo docker rm skale-ci-\$J

    sudo docker run -d -e catchupIntervalMs=60000 --cap-add SYS_ADMIN --name=skale-ci-\$J -v $REMOTE_HOME/shared_space:/shared_space -v $REMOTE_HOME/skale_node_data:/skale_node_data -v $REMOTE_HOME/data_dir/\$J:/data_dir -p 1\$((2+J))31-1\$((2+J))39:1\$((2+J))31-1\$((2+J))39/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 300 --restart=always skalenetwork/schain:$SKALED_RELEASE --http-port 1\$((2+J))34 --ws-port 1\$((2+J))33 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 4 --web3-trace --enable-debug-behavior-apis --aa no --sgx-url ${SGX_URL} --shared-space-path /shared_space/data

    done

	****

done

wait

cd "$ORIG_CWD"
