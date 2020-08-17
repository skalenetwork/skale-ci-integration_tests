#!/bin/bash

# ./run_tests.sh -g skale-manager
# ./run_tests.sh -s skale-manage+ts_1
# ./run_tests.sh -t skale-manager+ts_1+schains_smoke_create_destroy
# ./run_tests.sh -a

export OPTION=$1
export VALUE=$2

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
skaled+contractsRunningTest+all"

integration_tests=()
while IFS= read -r line ; do integration_tests+=($line); done <<< "$INTEGRATION_TESTS"

tests_in_action=()

case "$OPTION" in

      "-g")
            # run all tests in group

            # validate filter format
            FILTER_SOFTWARE_UNDER_TEST=$(echo $VALUE | cut -d'+' -f1)

            FILTER=$FILTER_SOFTWARE_UNDER_TEST

            for integration_test in ${integration_tests[@]}
            do
                SOFTWARE_UNDER_TEST=$(echo $integration_test | cut -d'+' -f1)
                TEST_SUITE=$(echo $integration_test | cut -d'+' -f2)

                # add test in group is valid
                if [ -z ${VALUE#"$FILTER"} ]; then
                    if [ $FILTER_SOFTWARE_UNDER_TEST == $SOFTWARE_UNDER_TEST ]; then
                        tests_in_action+=("$integration_test")
                    fi
                fi
            done
      ;;


      "-s")
            # run all tests in suite

            # validate filter format
            FILTER_SOFTWARE_UNDER_TEST=$(echo $VALUE | cut -d'+' -f1)
            FILTER_TEST_SUITE=$(echo $VALUE | cut -d'+' -f2)

            FILTER=$FILTER_SOFTWARE_UNDER_TEST+$FILTER_TEST_SUITE

            for integration_test in ${integration_tests[@]}
            do
                SOFTWARE_UNDER_TEST=$(echo $integration_test | cut -d'+' -f1)
                TEST_SUITE=$(echo $integration_test | cut -d'+' -f2)

                # add test in testsuite is valid
                if [ -z ${VALUE#"$FILTER"} ]; then
                    if [ $FILTER_SOFTWARE_UNDER_TEST == $SOFTWARE_UNDER_TEST ] | [ $FILTER_TEST_SUITE == $TEST_SUITE ]; then
                        tests_in_action+=("$integration_test")
                    fi
                fi
            done
      ;;


      "-t")
            # run one test

            tests_in_action=("$VALUE")

      ;;


      "-a")
            # run all tests

            tests_in_action=("${integration_tests[@]}")

      ;;


      *)
            echo "Option [${OPTION}] doesn't exist."
            false
      ;;
esac


echo "Tests in action --->"
for test in ${tests_in_action[@]}
do
    printf "%s\n" "$test"
done
echo "<--- Tests in action"

# validate that tests is exist
for test_in_action in ${tests_in_action[@]}
do
    if [[ ! " ${integration_tests[@]} " =~ " ${test_in_action} " ]]; then
        echo
        echo "----- ERROR -----"
        echo "Test [${test_in_action}] doesnt exist. Use from list:"
        echo
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
