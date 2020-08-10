#!/bin/bash

export TEST_IN_ACTION=$1
tests_in_action=($TEST_IN_ACTION)

export INTEGRATION_TESTS="\
skale-manager+ts_1+schains_smoke_create_destroy
skale-manager+ts_1+schains_create_destroy
skale-manager+ts_1+node_rotation
skale-manager+ts_1+schains_delete_all
skale-manager+ts_1+get_schains_quantity
skaled+load_js+run_angry_cats
skaled+internals+pytest
skaled+load_python"

integration_tests=()
while IFS= read -r line ; do integration_tests+=($line); done <<< "$INTEGRATION_TESTS"

echo "${integration_tests[@]}"
echo "${tests_in_action[@]}"

# validate that tests is exist
for test_in_action in ${tests_in_action[@]}
do
    if [[ ! " ${integration_tests[@]} " =~ " ${test_in_action} " ]]; then
        echo
        echo "----- ERROR -----"
        echo "Test [${test_in_action}] doesnt exist. Use from list:"
        echo "$INTEGRATION_TESTS"
        echo "-----------------"
        exit 1
    fi
done

export REPO_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export INTEGRATION_TESTS_DIR=$REPO_ROOT_DIR/integration_tests
echo "INTEGRATION_TESTS_DIR = $INTEGRATION_TESTS_DIR"

for test_in_action in ${tests_in_action[@]}
do
    SOFTWARE_UNDER_TEST=$(echo $test_in_action | cut -d'+' -f1)
    echo "SOFTWARE_UNDER_TEST = $SOFTWARE_UNDER_TEST"

    TEST_SUITE=$(echo $test_in_action | cut -d'+' -f2)
    echo "TEST_SUITE = $TEST_SUITE"

    TEST_RUNNER_SCRIPT=$INTEGRATION_TESTS_DIR/$SOFTWARE_UNDER_TEST/$TEST_SUITE/test.sh && test $TEST_RUNNER_SCRIPT

    TEST_NAME=$(echo $test_in_action | cut -d'+' -f3)
    echo "TEST_NAME = $TEST_NAME"

    bash $TEST_RUNNER_SCRIPT $TEST_NAME

done
