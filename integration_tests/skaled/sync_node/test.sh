#!/bin/bash

echo
echo "----- integration_tests/skaled/sync_node/test.sh ----- begin"

export SYNC_NODE=$INTEGRATION_TESTS_DIR/skaled/sync_node
echo "SYNC_NODE = $SYNC_NODE"

TEST_NAME=$1
SGX_URL="https://34.223.63.227:1026"

# exit children on our own exit
trap 'kill $(jobs -p)' EXIT

. $SKALED_PROVIDER/get_skaled.sh

cd $SYNC_NODE

_die() {
  printf "❌  "
  "${@}" 1>&2
  #. $SKALED_PROVIDER/free_skaled.sh
  exit 1
}

die() {
  _die echo "${@}"
}

run_4_nodes() {
  $SYNC_NODE/third_party/skaled-debug/create_btrfs.sh
  rm -rf btrfs/*
  cd btrfs
  SGX_URL=$SGX_URL $SYNC_NODE/third_party/config_tools/make_configs.sh 4 127.0.0.1:1231,127.0.0.2:1331,127.0.0.3:1431,127.0.0.1:1531 $SYNC_NODE/config_addons.json
  for I in {1..4}
  do
    mkdir $I
    mv config$I.json ./$I/config.json
    NO_ULIMIT_CHECK=1 DATA_DIR=./$I $SKTEST_EXE -d $I --config ./$I/config.json --sgx-url $SGX_URL --http-port 1$((I+1))34 --web3-trace -v 4 2>$I/aleth.err 1>$I/aleth.out &
  done
  cd ..
  sleep 20
}

query() {
    URL=$1
    FUNC=$2
    PARAMS=$3
    RESP=$(curl -s -S -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"$FUNC\",\"params\":[$PARAMS],\"id\":1}" $URL)
    STATUS=$?

    ERR=$(echo "$RESP" | jq .error)
    if [[ $STATUS != 0 || "$ERR" != "null" ]]
    then
	echo "$URL $FUNC $PARAMS" >&2
        echo "$RESP" >&2
    fi

    echo "$RESP" | jq .result 
    return $STATUS
}

query_wait() {
    EXPECT=$1
    shift
    while [[ $(query $@) != "$EXPECT" ]]
    do
        sleep 1
    done
}

check_started() {
	sleep 20
	query $1 eth_blockNumber || die "Sync Node not up"
}

check_block_hashes() {
	BLOCK1=$( curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":2}' $1 | jq .result )
	BLOCK2=$( curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":2}' $2 | jq .result )
	echo "BLOCK1=$BLOCK1 BLOCK2=$BLOCK2"
}

case "$TEST_NAME" in

      "sync_simple")

            echo
            echo "----- integration_tests/skaled/sync_node/test.sh::sync_simple -----"
	    run_4_nodes
	    cd btrfs
	    python3 ../third_party/config_tools/config.py merge 1/config.json ../config_addons_sync.json >config_sync.json
	    mkdir 5
	    rm -rf 5/*
	    mv config_sync.json ./5/config.json
	    NO_ULIMIT_CHECK=1 DATA_DIR=./5 $SKTEST_EXE -d 5 --config ./5/config.json --web3-trace -v 4 2>5/aleth.err 1>5/aleth.out &
	    check_started http://127.0.0.55:5131
	    check_block_hashes  http://127.0.0.55:5131 http://127.0.0.1:1234

      ;;

      "archive_node_block_rotation")

            echo
            echo "----- integration_tests/skaled/sync_node/test.sh::archive_node_block_rotation -----"

	    echo "Starting 4 nodes"
	    run_4_nodes

	    echo "Waiting for block 1 = null"
	    query_wait null http://127.0.0.1:1234 eth_getBlockByNumber \"0x1\",false

	    echo "Waiting 2 snapshots"
	    sleep 120

	    echo "Starting sync node"
	    cd btrfs
	    python3 ../third_party/config_tools/config.py merge 1/config.json ../config_addons_sync.json >config_sync.json
	    mkdir 5
	    rm -rf 5/*
	    mv config_sync.json ./5/config.json

	    NO_ULIMIT_CHECK=1 DATA_DIR=./5 $SKTEST_EXE -d 5 --config ./5/config.json --sgx-url="$SGX_URL" --web3-trace -v 4 2>5/aleth.err 1>5/aleth.out &

	    echo "Checking it started"
	    check_started http://127.0.0.55:5131

	    echo "Checking it started from snapshot"
	    b1="$(query http://127.0.0.55:5131 eth_getBlockByNumber \"0x1\",false)"
	    b_start="$(query http://127.0.0.55:5131 eth_blockNumber)"
	    echo "Query block 1: $b1"
	    echo "Starting block = $b_start"
	    test "$b1"  = "null" || die "Sync node started should not have block 0x1"

	    echo "Waiting for current block to disappear on normal node"
	    query_wait null http://127.0.0.1:1234 eth_getBlockByNumber $b_start,false
	    b_norm="$(query http://127.0.0.1:1234 eth_getBlockByNumber $b_start,false)"
	    test "$b_norm" = "null" || die "Block $b_start should disappear from normal node"

	    echo "Ckecking it is present on sync node"
	    b_sync="$(query http://127.0.0.55:5131 eth_getBlockByNumber $b_start,false)"
	    test "$b_sync" != "null" || die "Blocks should not disappear from sync node"

	    echo "Checking that sync node catches up"
	    b_after="$(query http://127.0.0.55:5131 eth_blockNumber)"
	    echo "sync node current block = $b_after"
	    test "$b_after" != "$b_start" || die "Sync node should do catch-up"

	    echo "Waiting 2 snapshots"
	    sleep 120

	    echo "Checking latest hashes"
	    bn="$(query http://127.0.0.55:5131 eth_blockNumber)"
	    echo "Block number = $bn"
	    hash_sync=$(query http://127.0.0.55:5131 eth_getBlockByNumber $bn,false | jq .hash)
	    echo "Hash on sync node = $hash_sync"
	    hash_normal=$(query http://127.0.0.1:1234 eth_getBlockByNumber $bn,false | jq .hash)
	    echo "Hash on normal node = $hash_normal"
	    [[ "$hash_normal" == "$hash_sync" ]] || die "Hashes are incorrect"

      ;;

      *)
            echo "Test [${TEST_NAME}] doesn't exist. Try another."
            false
      ;;
esac

result=$?

echo "----- integration_tests/skaled/sync_node/test.sh ----- end"
echo

exit $result
