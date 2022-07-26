#!/bin/bash

echo
echo "----- integration_tests/skaled/api/test.sh ----- begin"

TEST_NAME=$1

export SKALED_API_TEST=$INTEGRATION_TESTS_DIR/skaled/api
echo "SKALED_API_TEST = $SKALED_API_TEST"

export CONFIGS_DIR=$SKALED_API_TEST/configs
echo "CONFIGS_DIR = $CONFIGS_DIR"

export SKALE_EXPERIMANTAL=$SKALED_API_TEST/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

. $SKALED_PROVIDER/get_skaled.sh $CONFIGS_DIR/accounts.json
export CHAINID="$CHAIN_ID"

cd $SKALE_EXPERIMANTAL/skaled-tests/test-events

result=0
node eth-subscribe.js ws://127.0.0.1:1233 || result=$?
node contract-once.js ws://127.0.0.1:1233 || result=$?
node contract-watch.js ws://127.0.0.1:1233 || result=$?

$SKALED_PROVIDER/free_skaled.sh

echo "----- integration_tests/skaled/api/test.sh ----- end"
echo

exit $result
