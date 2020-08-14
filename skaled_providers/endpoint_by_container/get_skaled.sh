# source it!

# params:
# SKALED_RELEASE - dockerhub schain container version
# arg1 - config with additional params (optional)

# returns
# ENDPOINT_URL - URL for running skaled instance
# CHAIN_ID - chainID
# SCHAIN_OWNER - account with money and/or special permissions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# destroy all skaled
docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q) || true

echo -- Prepare data_dir --
rm -rf $SCRIPT_DIR/data_dir
mkdir $SCRIPT_DIR/data_dir

echo -- Prepare config --
python3 $SCRIPT_DIR/config.py merge $SCRIPT_DIR/config0.json ${@:1} >$SCRIPT_DIR/data_dir/config.json

echo -- Get schain image --
docker pull skalenetwork/schain:$SKALED_RELEASE

echo -- Run container --
docker run -d -v $SCRIPT_DIR/data_dir:/data_dir -p	127.0.0.1:1234:1234/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 40 skalenetwork/schain:$SKALED_RELEASE --http-port 1234 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 3 --web3-trace --enable-debug-behavior-apis --aa no

export ENDPOINT_URL="http://127.0.0.1:1234"
export CHAIN_ID=$( python3 $SCRIPT_DIR/config.py extract $SCRIPT_DIR/data_dir/config.json params.chainID )
export SCHAIN_OWNER=$( python3 $SCRIPT_DIR/config.py extract $SCRIPT_DIR/data_dir/config.json skaleConfig.sChain.schainOwner )

sleep 5
