#!/bin/bash

export TEST_IN_ACTION=$1
tests_in_action=($TEST_IN_ACTION)

# all possible tests
export INTEGRATION_TESTS="\
skale-manager+ts_1+schains_smoke_create_destroy
skale-manager+ts_1+schains_create_destroy
skale-manager+ts_1+node_rotation
skale-manager+ts_1+schains_delete_all
skale-manager+ts_1+get_schains_quantity
skaled+internals+pytest
skaled+load_python+all
skaled+load_js+run_angry_cats
skaled+contractsRunningTest+all
skaled+filestorage+all"

integration_tests=()
while IFS= read -r line ; do integration_tests+=($line); done <<< "$INTEGRATION_TESTS"

# if any test name is provided then run all possible tests
[ -z $TEST_IN_ACTION ] && tests_in_action=("${integration_tests[@]}")

echo "Tests in action --->"
for test in ${tests_in_action[@]}
do
    printf "%s\n" "$test"
done
echo "<--- Tests in action"

# validate that tests is exist
# TODO: separate this code into function
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
export SKALED_PROVIDERS_DIR=$REPO_ROOT_DIR/skaled_providers
echo "SKALED_PROVIDERS_DIR = $SKALED_PROVIDERS_DIR"

# read environment variables from config file
ENVARS_FILE=$REPO_ROOT_DIR/.env
set -a # automatically export all variables
. $ENVARS_FILE
set +a

# environment variables test session depends
ENVARS="\
PROJECT
SUITE
TEST
SKALED_PROVIDER
SKALED_RELEASE"

envars=()
while IFS= read -r line ; do envars+=($line); done <<< "$ENVARS"

# print
for envar in ${envars[@]}
do
    echo "${envar} = " ${!envar}
    if [[ -z ${!envar} ]]; then
        echo
        echo "----- ERROR -----"
        echo "Environment variable [${envar}] undefined"
        echo "-----------------"
        exit 1
    fi
done


SKALED_PROVIDER=$(realpath $SKALED_PROVIDERS_DIR/$SKALED_PROVIDER) || true
echo SKALED_PROVIDER = $SKALED_PROVIDER

result=0

for test_in_action in ${tests_in_action[@]}
do
    SOFTWARE_UNDER_TEST=$(echo $test_in_action | cut -d'+' -f1)
    echo "SOFTWARE_UNDER_TEST = $SOFTWARE_UNDER_TEST"

    TEST_SUITE=$(echo $test_in_action | cut -d'+' -f2)
    echo "TEST_SUITE = $TEST_SUITE"

    TEST_RUNNER_SCRIPT=$INTEGRATION_TESTS_DIR/$SOFTWARE_UNDER_TEST/$TEST_SUITE/test.sh && test $TEST_RUNNER_SCRIPT

    TEST_NAME=$(echo $test_in_action | cut -d'+' -f3)
    echo "TEST_NAME = $TEST_NAME"

    bash $TEST_RUNNER_SCRIPT $TEST_NAME || result=$?

done

exit $result
