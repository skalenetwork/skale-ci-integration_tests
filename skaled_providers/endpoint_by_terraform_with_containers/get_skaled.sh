# source it!

# params:
# SKALED_RELEASE - dockerhub schain container version
# NUM_NODES - number of hosts to launch
# arg1 - config with additional params (optional)

# returns
# ENDPOINT_URL - URL for running skaled instance
# CHAIN_ID - chainID
# SCHAIN_OWNER - account with money and/or special permissions

export NUM_NODES="${NUM_NODES:-4}"
export SKALED_RELEASE="${SKALED_RELEASE:-develop-latest}"
export NUM_SCHAINS="${NUM_SCHAINS:-5}"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

#SGX_URL="https://35.161.69.138:1026"
#SGX_URL="https://45.76.3.64:1026"
SGX_URL="https://34.223.63.227:1026"

echo -- Free skaled --
./free_skaled.sh || true

echo -- Terraform --
cd tf
if [[ ! -f ~/.ssh/id_rsa ]]
then
	ssh-keygen -f ~/.ssh/id_rsa -N ""
fi
cat ~/.ssh/id_rsa.pub >>tf_scripts/scripts/authorized_keys
# allow something to root too (for access to /skale_node_data)
sudo mkdir /root/.ssh || true
sudo cp ~/.ssh/id_rsa* /root/.ssh
./create.sh
cd ..

for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
	LONG_IPS[$i]=${IPS[$i]}:1231
done

set -x
SGX_URL="$SGX_URL" ./config_tools/make_configs.sh $NUM_NODES $(IFS=$','; echo "${LONG_IPS[*]}") $1
echo -- Prepare nodes ---

#input: $IP, $I
PARALLEL_FUNC () {

	scp -o "StrictHostKeyChecking no" config$I.json ubuntu@$IP:/home/ubuntu/config.json
	scp -o "StrictHostKeyChecking no" filebeat.yml ubuntu@$IP:/home/ubuntu
	scp -o "StrictHostKeyChecking no" create_btrfs.sh ubuntu@$IP:/home/ubuntu

	scp -r -o "StrictHostKeyChecking no" skaled-debug/skaled_monitor ubuntu@$IP:/home/ubuntu
	sudo scp -r -o "StrictHostKeyChecking no" /skale_node_data ubuntu@$IP:/home/ubuntu

	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****

        sudo fallocate -l 1G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile

	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo docker pull docker.elastic.co/beats/filebeat:7.3.1
	sudo chmod go-w filebeat.yml
	sudo chown root:root filebeat.yml
	sudo docker run -d --network host -u root -e FILEBEAT_HOST=3.17.12.121:5000 -v /home/ubuntu/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro -v /var/lib/docker:/var/lib/docker:ro -v /var/run/docker.sock:/var/run/docker.sock docker.elastic.co/beats/filebeat:7.3.1

	sudo BTRFS_DIR_PATH=data_dir ./create_btrfs.sh
	sudo chown \$USER:\$USER data_dir
        mkdir shared_space
        mkdir shared_space/data

	sudo docker pull skalenetwork/schain:$SKALED_RELEASE

	for J in {0..0}
	do

		#mv config.json data_dir/config.json
		mkdir data_dir/\$J

		sed "s/1231,/1\$((2+J))31,/g" config.json > data_dir/\$J/config.json

		#sudo docker start skale-ci-\$J
		sudo docker run -d -e catchupIntervalMs=60000 --cap-add SYS_ADMIN --name=skale-ci-\$J -v /home/ubuntu/shared_space:/shared_space -v /home/ubuntu/skale_node_data:/skale_node_data -v /home/ubuntu/data_dir/\$J:/data_dir -p 1\$((2+J))31-1\$((2+J))39:1\$((2+J))31-1\$((2+J))39/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 60 --restart=always -m 1g skalenetwork/schain:$SKALED_RELEASE --http-port 1\$((2+J))34 --ws-port 1\$((2+J))33 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 3 --web3-trace --enable-debug-behavior-apis --aa no --sgx-url ${SGX_URL} --shared-space-path /shared_space/data

	done

	cd skaled_monitor
	sudo ./node-side-monitor.sh </dev/null 2>/dev/null >/dev/null &
	cd ..

	****

}

./make_prom_targets.sh >skale_ci.yml
ssh -o "StrictHostKeyChecking no" -i ~/grafana_ci root@116.203.203.249 <<- 111
sudo -i
cat >/opt/prometheus/conf/skale_ci.yml <<- 222
$(cat skale_ci.yml)
222
docker restart prometheus
111

I=0
for IP in ${IPS[*]} #:0:11}
do
	I=$((I+1))
	IP=$IP I=$I PARALLEL_FUNC&
done

wait

sleep 30	# sometimes transaction script cannot connect, so wait

export ENDPOINT_URL="http://${IPS[0]}:1234"
export IPS=
export PORTS=(1234)
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"
