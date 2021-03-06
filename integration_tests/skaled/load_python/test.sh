#!/bin/bash

echo
echo "----- integration_tests/skaled/load_python/test.sh ----- begin"

TEST_NAME=$1

export LOAD_PYTHON=$INTEGRATION_TESTS_DIR/skaled/load_python
export SKALE_NODE_TESTS=$LOAD_PYTHON/third_party/skale-node-tests
echo "SKALE_NODE_TESTS = $SKALE_NODE_TESTS"

. $SKALED_PROVIDER/get_skaled.sh $LOAD_PYTHON/accounts.json

cd $SKALE_NODE_TESTS

source venv/bin/activate
python -V
pip3 -V

# to fix: test_race.py
python3 sktest_performance.py
result=$?

echo "----- integration_tests/skaled/load_python/test.sh ----- end"
echo

exit $result
