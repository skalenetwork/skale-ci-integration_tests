#!/bin/bash

echo
echo "----- integration_tests/skaled/upgrade_test/test.sh ----- begin"

TEST_NAME=$1

export SKALED_UPGRADE_TEST=$INTEGRATION_TESTS_DIR/skaled/upgrade_test
echo "SKALED_UPGRADE_TEST = $SKALED_UPGRADE_TEST"

export SKALE_NODE_TESTS=$SKALED_UPGRADE_TEST/third_party/skale-node-tests
echo "SKALE_NODE_TESTS = $SKALE_NODE_TESTS"

SKALED_PROVIDER=$SKALED_PROVIDERS_DIR/binary_from_container

cd $SKALE_NODE_TESTS

#VERSIONS=(3.7.3-stable.0 3.7.5-stable.0 3.14.9-stable.1 3.14.9-stable.3)
VERSIONS=(3.14.9-stable.3)

LEN=${#VERSIONS[@]}

result=0

for START_VERSION_I in $(seq 0 $(( LEN - 1 )) )
do

  echo "=== Testing upgrade from version ${VERSIONS[$START_VERSION_I]} ==="

  unset SKALED_TEST_LAST_GOOD_BLOCK_FOR_AMSTERDAM_FIX

  BTRFS_DIR_PATH=btrfs ../skaled-debug/create_btrfs.sh

  for VERSION_I in $(seq $START_VERSION_I $(( LEN - 1 )) )
  do
    VERSION=${VERSIONS[$VERSION_I]}
    echo "== Deploying version $VERSION =="

    SKALED_RELEASE=$VERSION . $SKALED_PROVIDER/get_skaled.sh ""
    DATA_DIR=btrfs SKTEST_EXE=$SKTEST_EXE NO_ULIMIT_CHECK=1 NUM_NODES=4 pytest-3 -s 'test_snapshot_api.py::test_2_snapshots'

    result=$?
    if [[ $result -ne 0 ]]; then break 2; fi

    if [[ "$VERSION" == "3.14.9-stable.3" ]]
    then
        echo "Enter last good block number:"
        read SKALED_TEST_LAST_GOOD_BLOCK_FOR_AMSTERDAM_FIX
        echo "SKALED_TEST_LAST_GOOD_BLOCK_FOR_AMSTERDAM_FIX=$SKALED_TEST_LAST_GOOD_BLOCK_FOR_AMSTERDAM_FIX"
    fi

  done

  break

done

# decide which tests to run in between
# check success somewhow

echo "----- integration_tests/skaled/upgrade_test/test.sh ----- end"
echo

exit $result
