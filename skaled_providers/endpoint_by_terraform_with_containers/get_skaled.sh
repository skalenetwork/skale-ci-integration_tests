# source it!

# params:
# SKALED_RELEASE - dockerhub schain container version
# NUM_NODES - number of hosts to launch
# arg1 - config with additional params (optional)
# --historic if need historic

# returns
# ENDPOINT_URL - URL for running skaled instance
# CHAIN_ID - chainID
# SCHAIN_OWNER - account with money and/or special permissions

export NUM_NODES="${NUM_NODES:-4}"
export SKALED_RELEASE="${SKALED_RELEASE:-develop-latest}"
export NUM_SCHAINS="${NUM_SCHAINS:-5}"

HISTORIC=false
if [[ "$@" == *"--historic"* ]]
then
  HISTORIC=true
fi

sudo echo "We need to obtain root now for future"

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

#SGX_URL="https://35.161.69.138:1026"
#SGX_URL="https://45.76.3.64:1026"
SGX_URL="https://167.235.155.228:1026"

echo -- Free skaled --
./free_skaled.sh || true

echo -- Terraform --
SUFFIX=
. create_instances.sh

echo -- Load IPs --
for i in $( seq 0 $(($NUM_NODES-1)) )
do
	IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
	if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
	LONG_IPS[$i]=${IPS[$i]}:1231
done

echo -- Make configs ---
set -x
if ! $HISTORIC
then
    SGX_URL="$SGX_URL" ./config_tools/make_configs.sh $NUM_NODES $(IFS=$','; echo "${LONG_IPS[*]}") "$1" --bind0
else
    HISTORIC_IP=$( jq -r '.public_ips.value."skale-ci-'${NUM_NODES}'"' tf/output.json )
    echo IP $HISTORIC_IP
    SGX_URL="$SGX_URL" ./config_tools/make_configs.sh $NUM_NODES $(IFS=$','; echo "${LONG_IPS[*]}") "$1" --bind0 --historic $HISTORIC_IP:1231
fi

echo -- Prepare nodes ---
. prepare_nodes.sh

echo -- Start nodes ---
. start_nodes.sh

#echo -- Create prom_targets ---
./make_prom_targets.sh >skale_ci.yml
ssh -o "StrictHostKeyChecking no" -i ~/grafana_ci root@116.203.203.249 <<- 111
sudo -i
cat >>/opt/prometheus/conf/skale_ci.yml <<- 222
$(cat skale_ci.yml)
222
docker restart prometheus
111

export ENDPOINT_URL="http://${IPS[0]}:1234"
echo "IPS=" ${IPS[*]}
export PORTS=(1234)
export CHAIN_ID=$( python3 config.py extract $SCRIPT_DIR/config_tools/config.json params.chainID )
export SCHAIN_OWNER=$( python3 config.py extract $SCRIPT_DIR/config_tools/config.json skaleConfig.sChain.schainOwner )

cd "$ORIG_CWD"
