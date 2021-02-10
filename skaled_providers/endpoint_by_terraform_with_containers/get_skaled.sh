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

#SGX_URL="https://35.161.69.138:1026"
SGX_URL="https://45.76.3.64:1026"
if [ ! -f uniq.txt ]
then
    ./prepare_keys.sh $NUM_NODES $SGX_URL
fi

echo -- Free skaled --
./free_skaled.sh || true

echo -- Terraform --
cd tf
if [[ ! -f ~/.ssh/id_rsa.pub ]]
then
	ssh-keygen -f ~/.ssh/id_rsa -N ""
fi
cat ~/.ssh/id_rsa.pub >>tf_scripts/scripts/authorized_keys
# allow something to root too (for access to /skale_node_data)
sudo cp ~/.ssh/id_rsa* /root/.ssh
./create.sh
cd ..

for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
done

set +x

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
        "blsPublicKey0": $(jq '.BLSPublicKey["'$((I-1))'"]["0"]' keys$NUM_NODES.json),
        "blsPublicKey1": $(jq '.BLSPublicKey["'$((I-1))'"]["1"]' keys$NUM_NODES.json),
        "blsPublicKey2": $(jq '.BLSPublicKey["'$((I-1))'"]["2"]' keys$NUM_NODES.json),
        "blsPublicKey3": $(jq '.BLSPublicKey["'$((I-1))'"]["3"]' keys$NUM_NODES.json)
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
                                 "url": "$SGX_URL",
                                 "keyShareName": "BLS_KEY:SCHAIN_ID:$(cat uniq.txt):NODE_ID:$I:DKG_ID:0",
                                 "t": 3,
                                 "n": 4,
                                 "BLSPublicKey0": $(jq '.BLSPublicKey["'$((I-1))'"]["0"]' keys$NUM_NODES.json),
                                 "BLSPublicKey1": $(jq '.BLSPublicKey["'$((I-1))'"]["1"]' keys$NUM_NODES.json),
                                 "BLSPublicKey2": $(jq '.BLSPublicKey["'$((I-1))'"]["2"]' keys$NUM_NODES.json),
                                 "BLSPublicKey3": $(jq '.BLSPublicKey["'$((I-1))'"]["3"]' keys$NUM_NODES.json),
                                 "commonBLSPublicKey0": $(jq '.commonBLSPublicKey["0"]' keys$NUM_NODES.json),
                                 "commonBLSPublicKey1": $(jq '.commonBLSPublicKey["1"]' keys$NUM_NODES.json),
                                 "commonBLSPublicKey2": $(jq '.commonBLSPublicKey["2"]' keys$NUM_NODES.json),
                                 "commonBLSPublicKey3": $(jq '.commonBLSPublicKey["3"]' keys$NUM_NODES.json)
                                }
                               }

			}
		}
	}
	****

	echo "$NODE_INFO" > _node_info.json

	python3 config.py merge config.json _node_info.json >config$I.json
done

set -x

rm _node_info.json

echo -- Prepare nodes ---

I=0
for IP in ${IPS[*]} #:0:11}
do
	
	I=$((I+1))

	scp -o "StrictHostKeyChecking no" config$I.json ubuntu@$IP:/home/ubuntu/config.json
	scp -o "StrictHostKeyChecking no" filebeat.yml ubuntu@$IP:/home/ubuntu
	scp -o "StrictHostKeyChecking no" create_btrfs.sh ubuntu@$IP:/home/ubuntu

	sudo scp -r -o "StrictHostKeyChecking no" /skale_node_data ubuntu@$IP:/home/ubuntu
	
	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
	
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo docker pull docker.elastic.co/beats/filebeat:7.3.1
	sudo chmod go-w filebeat.yml
	sudo chown root:root filebeat.yml
	sudo docker run -d --network host -u root -e FILEBEAT_HOST=3.17.12.121:5000 -v /home/ubuntu/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro -v /var/lib/docker:/var/lib/docker:ro -v /var/run/docker.sock:/var/run/docker.sock docker.elastic.co/beats/filebeat:7.3.1

	#sudo rm -rf data_dir	
	#mkdir data_dir	
	sudo BTRFS_DIR_PATH=data_dir ./create_btrfs.sh
	sudo chown \$USER:\$USER data_dir
	
	sudo docker pull skalenetwork/schain:$SKALED_RELEASE
	
	for J in {0..0}
	do

		#mv config.json data_dir/config.json
		mkdir data_dir/\$J
	
		sed "s/1231,/1\$((2+J))31,/g" config.json > data_dir/\$J/config.json

		sudo docker run -d -e catchupIntervalMs=60000 --cap-add SYS_ADMIN --name=skale-ci-$I-\$J -v /home/ubuntu/skale_node_data:/skale_node_data -v /home/ubuntu/data_dir/\$J:/data_dir -p 1\$((2+J))31-1\$((2+J))39:1\$((2+J))31-1\$((2+J))39/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 40 skalenetwork/schain:$SKALED_RELEASE --http-port 1\$((2+J))34 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 2 --web3-trace --enable-debug-behavior-apis --aa no
	
	done
	
	****

done

export ENDPOINT_URL="http://${IPS[0]}:1234"
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"

sleep 5
