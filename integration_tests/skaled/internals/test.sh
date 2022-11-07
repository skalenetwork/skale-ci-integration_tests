#!/bin/bash

# fail on first fail
set -e

echo
echo "----- integration_tests/skaled/internals/test.sh ----- begin"

TEST_NAME=$1

export INTERNALS=$INTEGRATION_TESTS_DIR/skaled/internals
export SKALE_NODE_TESTS=$INTERNALS/third_party/skale-node-tests
echo "SKALE_NODE_TESTS = $SKALE_NODE_TESTS"

# use "" to make subscript's arguments empty
. $SKALED_PROVIDER/get_skaled.sh ""

cd $SKALE_NODE_TESTS

source venv/bin/activate
python -V
pip3 -V

case "$TEST_NAME" in

      "pytest")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::pytest -----"

            pytest --full-trace --showlocals -v -s test_chainid.py test_stop.py test_rotation.py test_race.py

      ;;

      "sktest_3of4")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::sktest_3of4 -----"

            ./sktest_3of4.sh

      ;;

      "sktest_snapshot")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::sktest_snapshot -----"

            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 sktest_snapshot.py
      ;;

      "test_node_rotation")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::test_node_rotation -----"

            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_download_snapshot[True-False]'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_download_snapshot[True-True]'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_download_snapshot[False-False]'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_download_snapshot[False-True]'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_restart'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_download_early'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_late_join'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_node_rotation.py::test_wrong_stateRoot_in_proposal'
      ;;

      "test_snapshot_api")

            echo
            echo "----- integration_tests/skaled/internals/test.sh::test_snapshot_api -----"

            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_snapshot_api.py::test_main'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_snapshot_api.py::test_corner_cases'
            sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_snapshot_api.py::test_download_download'
            #sudo -E ../../create_btrfs.sh; sudo -E NO_ULIMIT_CHECK=1 DATA_DIR=btrfs ./venv/bin/python3 -m pytest -s 'test_snapshot_api.py::test_stateRoot_conflict'
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
