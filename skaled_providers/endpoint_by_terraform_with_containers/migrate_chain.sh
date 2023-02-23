#!/bin/bash

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

sudo echo "We need to obtain root now for future"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

SGX_URL="https://34.223.63.227:1026"

# read tf/output.json -> OLD_IPS, OLD_LONG_IPS
for i in $( seq 0 $(($NUM_NODES-1)) )
do
	OLD_IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
	OLD_LONG_IPS[$i]=${IPS[$i]}:1231
done

echo -- Terraform --
SUFFIX=_young
. create_instances.sh

# read tf/output_young.json -> IPS, LONG_IPS
for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output_young.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
	LONG_IPS[$i]=${IPS[$i]}:1231
done

echo -- Make configs ---
set -x
SGX_URL="$SGX_URL" ./config_tools/make_configs.sh $NUM_NODES $(IFS=$','; echo "${LONG_IPS[*]}") "$1" --bind0

echo -- Prepare nodes ---
. prepare_nodes.sh

echo -- Copy old data ---

# $OLD_IP $NEW_IP
# $I for different names
HOST_COPY(){
    
	# need keys from old in new
    ssh -o "StrictHostKeyChecking no" ubuntu@$OLD_IP <<- ****
    sudo -i
    chmod -R +xr /root
    if [[ ! -f ~/.ssh/id_rsa ]]
    then
        ssh-keygen -f ~/.ssh/id_rsa -N ""
    fi
	****
	
	scp -o "StrictHostKeyChecking no" ubuntu@$OLD_IP:/root/.ssh/id_rsa.pub id_rsa_$I.pub
	ssh-copy-id -o "StrictHostKeyChecking no" -f -i id_rsa_$I.pub ubuntu@$NEW_IP
	
	# copy data!
	ssh -o "StrictHostKeyChecking no" ubuntu@$OLD_IP <<- ****
	sudo scp -o "StrictHostKeyChecking no" -r /home/ubuntu/data_dir ubuntu@$NEW_IP:/home/ubuntu/data_dir
	****
}

for i in $( seq 0 $(($NUM_NODES-1)) )
do
	I=$i OLD_IP=${OLD_IPS[$i]} NEW_IP=${IPS[$i]} HOST_COPY&
done

wait

#echo "waiting"
#read dummy

echo -- Free old nodes --
./free_skaled.sh
# pretend new nodes are old ones (for free_skaled.sh)
mv tf/output_young.json tf/output.json  
mv tf/tf_scripts/terraform.tfstate_young tf/tf_scripts/terraform.tfstate

echo -- Start nodes ---
. start_nodes.sh

./make_prom_targets.sh >skale_ci.yml
ssh -o "StrictHostKeyChecking no" -i ~/grafana_ci root@116.203.203.249 <<- 111
sudo -i
cat >/opt/prometheus/conf/skale_ci.yml <<- 222
$(cat skale_ci.yml)
222
docker restart prometheus
111

export ENDPOINT_URL="http://${IPS[0]}:1234"
export IPS=
export PORTS=(1234)
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"
