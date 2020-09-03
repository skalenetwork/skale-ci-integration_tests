# source it!

# params:
# SKALED_RELEASE - dockerhub schain container version
# NUM_NODES - number of hosts to launch
# arg1 - config with additional params (optional)

# returns
# ENDPOINT_URL - URL for running skaled instance
# CHAIN_ID - chainID
# SCHAIN_OWNER - account with money and/or special permissions

set -x

NUM_NODES="${NUM_NODES:-2}"
SKALED_RELEASE="${SKALED_RELEASE:develop-latest}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

echo -- Free skaled --
./free_skaled.sh || true

echo -- Terraform --
cd tf
ssh-keygen -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub >>tf_scripts/scripts/authorized_keys
./create.sh
cd ..

for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
done

echo -- Prepare config --

echo '{ "skaleConfig": {"sChain": { "nodes": [' > _nodes.json

I=0
for IP in ${IPS[*]}
do
	
	I=$((I+1))

	read -r -d '' NODE_CFG <<- ****
	{
    	"nodeID": $I,
    	"ip": "$IP",
    	"basePort": 1231,
    	"schainIndex" : $I,
    	"publicKey":""
	}
	****

	echo "$NODE_CFG" >> _nodes.json

	if [[ "$I" != "$NUM_NODES" ]]; then
		echo "," >>_nodes.json
	fi

done

echo "] } } }" >> _nodes.json

python3 config.py merge config0.json ${@:1} _nodes.json >config.json
rm _nodes.json

I=0
for IP in ${IPS[*]}
do
	
	I=$((I+1))

	read -r -d '' NODE_INFO <<- ****
	{
		"skaleConfig": {
			"nodeInfo": {
	      				"nodeName": "Node$I",
	      				"nodeID": $I,
	      				"bindIP": "0.0.0.0",
	      				"basePort": 1231
			}
		}
	}
	****

	echo "$NODE_INFO" > _node_info.json

	python3 config.py merge config.json _node_info.json >config$I.json

done

rm _node_info.json

echo -- Prepare nodes —

I=0
for IP in ${IPS[*]}
do
	
	I=$((I+1))

	scp -o "StrictHostKeyChecking no" config$I.json ubuntu@$IP:/home/ubuntu/config.json

	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****

	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo rm -rf data_dir	
	mkdir data_dir
	
	mv config.json data_dir/config.json
	
	sudo docker pull skalenetwork/schain:$SKALED_RELEASE
	sudo docker run -d -v /home/ubuntu/data_dir:/data_dir -p 1231-1239:1231-1239/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 40 skalenetwork/schain:$SKALED_RELEASE --http-port 1234 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 3 --web3-trace --enable-debug-behavior-apis --aa no
	
	****

done

export ENDPOINT_URL="http://${IPS[0]}:1234"
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"

sleep 5
