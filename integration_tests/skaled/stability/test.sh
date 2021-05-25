#!/bin/bash

echo
echo "----- integration_tests/skaled/stability/test.sh ----- begin"

TEST_NAME=$1

export STABILITY=$INTEGRATION_TESTS_DIR/skaled/stability

. $SKALED_PROVIDER/get_skaled.sh $STABILITY/accounts.json

cd $STABILITY

source venv/bin/activate
python -V
pip3 -V

python3 sktest_performance.py
result=$?

echo "----- integration_tests/skaled/stability/test.sh ----- end"
echo

exit $result
