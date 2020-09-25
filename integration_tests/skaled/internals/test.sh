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

case "$TEST_NAME" in

      "all")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::all -----"

            # to fix: test_race.py
            pytest --full-trace --showlocals -v -s test_chainid.py test_stop.py test_rotation.py

      ;;

      "sktest_snapshot")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::sktest_snapshot -----"

            sudo ./create_btrfs.sh; sudo NO_ULIMIT_CHECK=1 DATA_DIR=btrfs python3 sktest_snapshot.py

      ;;

      "sktest_node_rotation")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::sktest_node_rotation -----"

            sudo ./create_btrfs.sh; sudo NO_ULIMIT_CHECK=1 DATA_DIR=btrfs python3 sktest_node_rotation.py

      ;;
      
      *)
            echo "Test [${TEST_NAME}] doesn't exist. Try another."
            false
      ;;
esac

result=$?

echo "----- integration_tests/skaled/internals/test.sh ----- end"
echo

exit $result
