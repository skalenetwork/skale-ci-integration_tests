# source it!

# params:
# SKALED_RELEASE - dockerhub schain container version
# REMOTE_USER
# arg1 - config with additional params (optional)

# returns
# ENDPOINT_URL - URL for running skaled instance
# CHAIN_ID - chainID
# SCHAIN_OWNER - account with money and/or special permissions

REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_HOME="/home/$REMOTE_USER"
if [ "$REMOTE_USER" = "root" ]
then
  REMOTE_HOME="/root"
fi

SKALED_RELEASE="${SKALED_RELEASE:-develop-latest}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"
                                                                                                                                  
#SGX_URL="https://35.161.69.138:1026"
#SGX_URL="https://45.76.3.64:1026"
SGX_URL=""

IPS=()
LONG_IPS=()
while read line ; do
        IPS+=($line)
        LONG_IPS+=($line:1231)
done <ips.txt

NUM_NODES=${#IPS[@]}

set -x
SGX_URL="$SGX_URL" ~/skale-node-tests/config_tools/make_configs.sh $NUM_NODES $(IFS=$','; echo "${LONG_IPS[*]}") $1   

echo -- Prepare nodes ---
exit
I=0
for IP in ${IPS[*]} #:0:11}
do
	
	I=$((I+1))

	scp -i ash_sydney.pem -o "StrictHostKeyChecking no" config$I.json $REMOTE_USER@$IP:$REMOTE_HOME/config.json
	scp -i ash_sydney.pem -o "StrictHostKeyChecking no" filebeat.yml $REMOTE_USER@$IP:$REMOTE_HOME
	scp -i ash_sydney.pem -o "StrictHostKeyChecking no" create_btrfs.sh $REMOTE_USER@$IP:$REMOTE_HOME
	
	scp -i ash_sydney.pem -r -o "StrictHostKeyChecking no" 1node-cat-cycle $REMOTE_USER@$IP:$REMOTE_HOME
	
	sudo scp -i ash_sydney.pem -r -o "StrictHostKeyChecking no" /skale_node_data $REMOTE_USER@$IP:$REMOTE_HOME
	
	ssh -i ash_sydney.pem -o "StrictHostKeyChecking no" $REMOTE_USER@$IP <<- ****
	
	curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -; sudo apt install -y nodejs
	cd 1node-cat-cycle
	npm install
	cd ..
	
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo docker pull docker.elastic.co/beats/filebeat:7.3.1
	sudo chmod go-w filebeat.yml
	sudo chown root:root filebeat.yml
	sudo docker run -d --network host -u root -e FILEBEAT_HOST=3.17.12.121:5000 -v $REMOTE_HOME/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro -v /var/lib/docker:/var/lib/docker:ro -v /var/run/docker.sock:/var/run/docker.sock docker.elastic.co/beats/filebeat:7.3.1

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

		sudo docker run -d -e catchupIntervalMs=60000 --cap-add SYS_ADMIN --privileged --name=skale-ci-$I-\$J -v $REMOTE_HOME/skale_node_data:/skale_node_data -v $REMOTE_HOME/data_dir/\$J:/data_dir -p 1\$((2+J))31-1\$((2+J))39:1\$((2+J))31-1\$((2+J))39/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 40 skalenetwork/schain:$SKALED_RELEASE --http-port 1\$((2+J))34 --ws-port 1\$((2+J))33 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 2 --web3-trace --enable-debug-behavior-apis --aa no
	
	done
	
	****

done

export ENDPOINT_URL="http://${IPS[0]}:1234"
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"

sleep 5
