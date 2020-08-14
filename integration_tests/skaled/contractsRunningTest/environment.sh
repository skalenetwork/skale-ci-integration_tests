#!/bin/bash

set -x

echo
echo "----- integration_tests/skaled/contractsRunningTest/environment.sh ----- begin"

export SKALED_CONTRACTS_TEST=$INTEGRATION_TESTS_DIR/skaled/contractsRunningTest
echo "SKALED_CONTRACTS_TEST = $SKALED_CONTRACTS_TEST"

export SKALE_EXPERIMANTAL=$SKALED_CONTRACTS_TEST/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

cd $SKALE_EXPERIMANTAL/l_sergiy/contractsRunningTest

yarnpkg install
npx truffle compile

echo "----- integration_tests/skaled/contractsRunningTest/environment.sh ----- end"
echo
