#!/bin/bash

echo
echo "----- integration_tests/skaled/load_js/test.sh ----- begin"

TEST_NAME=$1

export SKALED_CONTRACTS_TEST=$INTEGRATION_TESTS_DIR/skaled/contractsRunningTest
echo "SKALED_CONTRACTS_TEST = $SKALED_CONTRACTS_TEST"

export CONFIGS_DIR=$SKALED_CONTRACTS_TEST/configs
echo "CONFIGS_DIR = $CONFIGS_DIR"

export SKALE_EXPERIMANTAL=$SKALED_CONTRACTS_TEST/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

. $SKALED_PROVIDER/get_skaled.sh $CONFIGS_DIR/accounts.json

cd $SKALE_EXPERIMANTAL/l_sergiy/contractsRunningTest

export ENDPOINT=$ENDPOINT_URL
export CHAINID=$CHAIN_ID

# from accounts.json
export INSECURE_PRIVATE_KEY="1016316fe598b437cfd518c02f67467385b018e61fd048325c7e7c9e5e07cd2a"
export INSECURE_PRIVATE_KEY_1="1016316fe598b437cfd518c02f67467385b018e61fd048325c7e7c9e5e07cd2a"
export INSECURE_PRIVATE_KEY_2="14e7e34f77749217477a6c36ddff3f5b5f217c67782dd7cc4ec4c0f9997f968b"

result=0
npx truffle deploy --network=test || result=$?
node ./index.js || result=$?

echo "----- integration_tests/skaled/load_js/test.sh ----- end"
echo

exit $result
