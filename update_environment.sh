#!/bin/bash

export TEST_SUITES="\
skale-manager+ts_1"

test_suites=()
while IFS= read -r line ; do test_suites+=($line); done <<< "$TEST_SUITES"

echo "$test_suites"

export REPO_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export INTEGRATION_TESTS_DIR=$REPO_ROOT_DIR/integration_tests
echo "INTEGRATION_TESTS_DIR = $INTEGRATION_TESTS_DIR"

for test_suite in ${test_suites[@]}
do
    SOFTWARE_UNDER_TEST=$(echo $test_suite | cut -d'+' -f1)
    echo "SOFTWARE_UNDER_TEST = $SOFTWARE_UNDER_TEST"

    TEST_SUITE=$(echo $test_suite | cut -d'+' -f2)
    echo "TEST_SUITE = $TEST_SUITE"

    export TEST_SUITE_ENVIRONMENT_SCRIPT=$INTEGRATION_TESTS_DIR/$SOFTWARE_UNDER_TEST/$TEST_SUITE/environment.sh && test $TEST_SUITE_ENVIRONMENT_SCRIPT
    echo "TEST_SUITE_ENVIRONMENT_SCRIPT = $TEST_SUITE_ENVIRONMENT_SCRIPT"
    bash $TEST_SUITE_ENVIRONMENT_SCRIPT

    export TEST_SUITE_CONFIG_SCRIPT=$INTEGRATION_TESTS_DIR/$SOFTWARE_UNDER_TEST/$TEST_SUITE/config.sh && test $TEST_SUITE_ENVIRONMENT_SCRIPT
    echo "TEST_SUITE_CONFIG_SCRIPT = $TEST_SUITE_CONFIG_SCRIPT"
    bash $TEST_SUITE_CONFIG_SCRIPT

done