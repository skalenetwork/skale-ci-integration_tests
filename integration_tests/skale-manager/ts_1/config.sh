#!/bin/bash

echo
echo "----- integration_tests/skale-manager/ts_1/update_configs.sh ----- begin"

export SKALE_MANAGER_TS_1=$INTEGRATION_TESTS_DIR/skale-manager/ts_1
echo "SKALE_MANAGER_TS_1 = $SKALE_MANAGER_TS_1"

export CONFIGS_DIR=$SKALE_MANAGER_TS_1/configs
echo "CONFIGS_DIR = $CONFIGS_DIR"

env_file_link=$(curl -L  -v  -H 'Authorization: Token ***REMOVED***' -H 'Accept: application/json; charset=utf-8; indent=4' 'http://ec2-3-12-129-250.us-east-2.compute.amazonaws.com/api2/repos/25d6f51f-254b-498e-937a-09dcbf810dd9/file/?p=/skale-ci-integration_tests/skale-manager/ts_1/.env.txt&reuse=1' | sed 's/"//g')
manager_file_link=$(curl -L  -v  -H 'Authorization: Token ***REMOVED***' -H 'Accept: application/json; charset=utf-8; indent=4' 'http://ec2-3-12-129-250.us-east-2.compute.amazonaws.com/api2/repos/25d6f51f-254b-498e-937a-09dcbf810dd9/file/?p=/skale-ci-integration_tests/skale-manager/ts_1/manager.txt&reuse=1' | sed 's/"//g')
ima_file_link=$(curl -L  -v  -H 'Authorization: Token ***REMOVED***' -H 'Accept: application/json; charset=utf-8; indent=4' 'http://ec2-3-12-129-250.us-east-2.compute.amazonaws.com/api2/repos/25d6f51f-254b-498e-937a-09dcbf810dd9/file/?p=/skale-ci-integration_tests/skale-manager/ts_1/ima.txt&reuse=1' | sed 's/"//g')

(cd "$CONFIGS_DIR" && curl -o .env $env_file_link)
(cd "$CONFIGS_DIR" && curl -o manager.json $manager_file_link)
(cd "$CONFIGS_DIR" && curl -o ima.json $ima_file_link)

echo "----- integration_tests/skale-manager/ts_1/update_configs.sh ----- end"
echo