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

sleep 20

cd $SKALED_LOAD_JS

case "$TEST_NAME" in

      "run_angry_cats")

            echo
            echo "----- integration_tests/skaled/load_js/test.sh::run_angry_cats -----"

            node $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle/cat-cycle.js $ENDPOINT_URL "" 10000 100

      ;;
      
      "skaled_chart")

            echo
            echo "----- integration_tests/skaled/load_js/test.sh::skaled_chart -----"

            ./skaled_to_chart.sh $ENDPOINT_URL&
            node $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle/cat-cycle.js $ENDPOINT_URL 1000000000 15000 2>&1 1>/dev/null&
            sleep 15000
            kill $(jobs -p)
            gnuplot skaled_chart.plt

      ;;

      *)
            echo "Test [${TEST_NAME}] doesn't exist. Try another."
            false
      ;;
esac

result=$?

$SKALED_PROVIDER/free_skaled.sh

echo "----- integration_tests/skaled/load_js/test.sh ----- end"
echo

exit $result
