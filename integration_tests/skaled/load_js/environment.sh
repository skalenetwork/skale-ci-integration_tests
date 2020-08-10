
#!/bin/bash

echo
echo "----- integration_tests/skaled/load_js/environment.sh ----- begin"

export SKALED_LOAD_JS=$INTEGRATION_TESTS_DIR/skaled/load_js
echo "SKALED_LOAD_JS = $SKALED_LOAD_JS"

export SKALE_EXPERIMANTAL=$SKALED_LOAD_JS/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

cd $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle

npm install $SKALE_EXPERIMANTAL/skaled-tests/cat-cycle

echo "----- integration_tests/skaled/load_js/environment.sh ----- end"
echo