#!/bin/bash

echo
echo "----- integration_tests/skaled/network/test.sh ----- begin"

export NETWORK=$INTEGRATION_TESTS_DIR/skaled/network

. $SKALED_PROVIDER/get_skaled.sh $NETWORK/accounts_plus_options.json

cd $NETWORK

sleep $((86400*3-3600))

. $SKALED_PROVIDER/free_skaled.sh

echo "----- integration_tests/skaled/stability/test.sh ----- end"
echo

exit 0
