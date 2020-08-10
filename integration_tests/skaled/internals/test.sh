#!/bin/bash

echo
echo "----- integration_tests/skaled/internals/test.sh ----- begin"

TEST_NAME=$1

export INTERNALS=$INTEGRATION_TESTS_DIR/skaled/internals
export SKALE_NODE_TESTS=$INTERNALS/third_party/skale-node-tests
echo "SKALE_NODE_TESTS = $SKALE_NODE_TESTS"

. $SKALED_PROVIDER/get_skaled.sh

cd $SKALE_NODE_TESTS

source venv/bin/activate
python -V
pip3 -V

# to fix: test_race.py
pytest --full-trace --showlocals -v -s test_chainid.py test_stop.py test_rotation.py


echo "----- integration_tests/skaled/internals/test.sh ----- end"
echo
