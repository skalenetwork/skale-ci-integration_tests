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
  . $SKALED_PROVIDER/free_skaled.sh
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
    NO_ULIMIT_CHECK=1 DATA_DIR=./$I $SKTEST_EXE -d $I --config ./$I/config.json --http-port 1$((I+1))34 -v 4 2>$I/aleth.err 1>$I/aleth.out &
  done
  cd ..
  sleep 20
}

check_started() {
	sleep 20
	curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $1 || die "Sync Node not up"
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
	    NO_ULIMIT_CHECK=1 DATA_DIR=./5 $SKTEST_EXE -d 5 --config ./5/config.json -v 4 2>5/aleth.err 1>5/aleth.out &
	    check_started http://127.0.0.55:5131
	    check_block_hashes  http://127.0.0.55:5131 http://127.0.0.1:1234
	    sleep 15000
            #node $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle/cat-cycle.js $ENDPOINT_URL 100

      ;;

      "archive_node_block_rotation")

            echo
            echo "----- integration_tests/skaled/sync_node/test.sh::archive_node_block_rotation -----"

            ./skaled_to_chart.sh $ENDPOINT_URL&
            node $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle/cat-cycle.js $ENDPOINT_URL 1000000000 15000 2>&1 1>/dev/null&
            sleep 15000
            kill $(jobs -p)
            gnuplot skaled_chart.plt

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
