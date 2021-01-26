#!/bin/bash

echo
echo "----- integration_tests/skaled/api/environment.sh ----- begin"

export SKALED_API_TEST=$INTEGRATION_TESTS_DIR/skaled/api
echo "SKALED_API_TEST = $SKALED_API_TEST"

export SKALE_EXPERIMANTAL=$SKALED_API_TEST/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

cd $SKALE_EXPERIMANTAL/skaled-tests/test-events

#rm -rf node_modules
npm install
result=$?

echo "----- integration_tests/skaled/api/environment.sh ----- end"
echo

exit $result
