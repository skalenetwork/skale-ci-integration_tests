# source it!

# params:
# SKTEST_EXE - path to skaled
# arg1 - config with additional params (optional)

# returns
# ENDPOINT_URL - URL for running skaled instance
# CHAIN_ID - chainID
# SCHAIN_OWNER - account with money and/or special permissions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

$SCRIPT_DIR/free_skaled.sh || true

echo -- Prepare data_dir --
rm -rf $SCRIPT_DIR/data_dir
mkdir $SCRIPT_DIR/data_dir

echo -- Prepare config --
python3 $SCRIPT_DIR/config.py merge $SCRIPT_DIR/config0.json ${@:1} >$SCRIPT_DIR/data_dir/config.json

echo -- Run binary --
DATA_DIR=$SCRIPT_DIR/data_dir $SKTEST_EXE --http-port 1234 --ws-port 1233 --config $SCRIPT_DIR/data_dir/config.json -d $SCRIPT_DIR/data_dir --ipcpath $SCRIPT_DIR/data_dir -v 4 --web3-trace --enable-debug-behavior-apis --aa no 2>$SCRIPT_DIR/data_dir/aleth.err >$SCRIPT_DIR/data_dir/aleth.out &

export ENDPOINT_URL="http://127.0.0.1:1234"
export CHAIN_ID=$( python3 $SCRIPT_DIR/config.py extract $SCRIPT_DIR/data_dir/config.json params.chainID )
export SCHAIN_OWNER=$( python3 $SCRIPT_DIR/config.py extract $SCRIPT_DIR/data_dir/config.json skaleConfig.sChain.schainOwner )

sleep 20
