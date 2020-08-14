#!/bin/bash

echo
echo "----- integration_tests/skaled/load_js/test.sh ----- begin"

TEST_NAME=$1

export SKALED_LOAD_JS=$INTEGRATION_TESTS_DIR/skaled/load_js
echo "SKALED_LOAD_JS = $SKALED_LOAD_JS"

export CONFIGS_DIR=$SKALED_LOAD_JS/configs
echo "CONFIGS_DIR = $CONFIGS_DIR"

export SKALE_EXPERIMANTAL=$SKALED_LOAD_JS/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

. $SKALED_PROVIDER/get_skaled.sh $CONFIGS_DIR/accounts.json

cd $SKALED_LOAD_JS

case "$TEST_NAME" in

      "run_angry_cats")

            echo
            echo "----- integration_tests/skaled/load_js/test.sh::run_angry_cats -----"

            node $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle/cat-cycle.js $ENDPOINT_URL 100

      ;;

      *)
            echo "Test [${TEST_NAME}] doesn't exist. Try another."
            false
      ;;
esac

result=$?

echo "----- integration_tests/skaled/load_js/test.sh ----- end"
echo

exit $result
