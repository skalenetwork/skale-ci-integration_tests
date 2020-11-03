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
SKALED_RELEASE="${SKALED_RELEASE:-develop-latest}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

echo -- Free skaled --
./free_skaled.sh || true

echo -- Terraform --
cd tf
if [[ ! -f ~/.ssh/id_rsa.pub ]]
then
	ssh-keygen -f ~/.ssh/id_rsa -N ""
fi
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
    	"publicKey":"0x$(echo $(jq '.result.publicKey' ecdsa$I.json) | xargs echo)",
        "blsPublicKey0": $(jq '.BLSPublicKey["'$((I-1))'"]["0"]' keys4.json),
        "blsPublicKey1": $(jq '.BLSPublicKey["'$((I-1))'"]["1"]' keys4.json),
        "blsPublicKey2": $(jq '.BLSPublicKey["'$((I-1))'"]["2"]' keys4.json),
        "blsPublicKey3": $(jq '.BLSPublicKey["'$((I-1))'"]["3"]' keys4.json)
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
	      				"basePort": 1231,
	      				"ecdsaKeyName": $(jq '.result.keyName' ecdsa$I.json),
	      				   "wallets": {
                                "ima": {
                                 "url": "https://45.76.3.64:1026",
                                 "keyShareName": "BLS_KEY:SCHAIN_ID:70314811531:NODE_ID:$I:DKG_ID:0",
                                 "t": 3,
                                 "n": 4,
                                 "BLSPublicKey0": $(jq '.BLSPublicKey["'$((I-1))'"]["0"]' keys4.json),
                                 "BLSPublicKey1": $(jq '.BLSPublicKey["'$((I-1))'"]["1"]' keys4.json),
                                 "BLSPublicKey2": $(jq '.BLSPublicKey["'$((I-1))'"]["2"]' keys4.json),
                                 "BLSPublicKey3": $(jq '.BLSPublicKey["'$((I-1))'"]["3"]' keys4.json),
                                 "commonBLSPublicKey0": $(jq '.commonBLSPublicKey["0"]' keys4.json),
                                 "commonBLSPublicKey1": $(jq '.commonBLSPublicKey["1"]' keys4.json),
                                 "commonBLSPublicKey2": $(jq '.commonBLSPublicKey["2"]' keys4.json),
                                 "commonBLSPublicKey3": $(jq '.commonBLSPublicKey["3"]' keys4.json)
                                }
                               }

			}
		}
	}
	****

	echo "$NODE_INFO" > _node_info.json

	python3 config.py merge config.json _node_info.json >config$I.json

done

rm _node_info.json

echo -- Prepare nodes ---

I=0
for IP in ${IPS[*]}
do
	
	I=$((I+1))

	scp -o "StrictHostKeyChecking no" config$I.json ubuntu@$IP:/home/ubuntu/config.json
	scp -o "StrictHostKeyChecking no" filebeat.yml ubuntu@$IP:/home/ubuntu/filebeat.yml

	sudo scp -r -o "StrictHostKeyChecking no" /skale_node_data ubuntu@$IP:/home/ubuntu
	
	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
	
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo docker pull docker.elastic.co/beats/filebeat:7.3.1
	sudo chmod go-w filebeat.yml
	sudo chown root:root filebeat.yml
	sudo docker run -d --network host -u root -e FILEBEAT_HOST=3.17.12.121:5000 -v /home/ubuntu/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro -v /var/lib/docker:/var/lib/docker:ro -v /var/run/docker.sock:/var/run/docker.sock docker.elastic.co/beats/filebeat:7.3.1

	sudo rm -rf data_dir	
	mkdir data_dir
	
	mv config.json data_dir/config.json
	
	sudo docker pull skalenetwork/schain:$SKALED_RELEASE
	sudo docker run -d --name=skale-ci-$I -v /home/ubuntu/skale_node_data:/skale_node_data -v /home/ubuntu/data_dir:/data_dir -p 1231-1239:1231-1239/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 40 skalenetwork/schain:$SKALED_RELEASE --http-port 1234 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 3 --web3-trace --enable-debug-behavior-apis --aa no
	
	****

done

export ENDPOINT_URL="http://${IPS[0]}:1234"
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"

sleep 5
