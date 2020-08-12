#!/bin/bash

echo
echo "----- integration_tests/skale-manager/ts_1/test.sh ----- begin"

TEST_NAME=$1

export SKALE_MANAGER_TS_1=$INTEGRATION_TESTS_DIR/skale-manager/ts_1
echo "SKALE_MANAGER_TS_1 = $SKALE_MANAGER_TS_1"

export CONFIGS_DIR=$SKALE_MANAGER_TS_1/configs
echo "CONFIGS_DIR = $CONFIGS_DIR"

# export and test configs
export ENV_FILE=$CONFIGS_DIR/.env && test -f $ENV_FILE
# export TFVARS_FILE=$CONFIGS_DIR/terraform.tfvars && test -f $TFVARS_FILE
export MANAGER_FILE=$CONFIGS_DIR/manager.json && test -f $MANAGER_FILE
export IMA_FILE=$CONFIGS_DIR/ima.json && test -f $IMA_FILE

set -a # automatically export all variables
. $ENV_FILE
set +a

export INTEGRATION_TESTS_FOR_SKALE_MANAGER=$SKALE_MANAGER_TS_1/third_party/integration_tests_for_skale-manager
echo "INTEGRATION_TESTS_FOR_SKALE_MANAGER = $INTEGRATION_TESTS_FOR_SKALE_MANAGER"

# create required
INTEGRATION_TESTS_FOR_SKALE_MANAGER_CONFIG_DIR=$INTEGRATION_TESTS_FOR_SKALE_MANAGER/config
mkdir -p $INTEGRATION_TESTS_FOR_SKALE_MANAGER_CONFIG_DIR
mkdir -p $INTEGRATION_TESTS_FOR_SKALE_MANAGER_CONFIG_DIR/nodes

cp $IMA_FILE $INTEGRATION_TESTS_FOR_SKALE_MANAGER_CONFIG_DIR
cp $MANAGER_FILE $INTEGRATION_TESTS_FOR_SKALE_MANAGER_CONFIG_DIR

cd $INTEGRATION_TESTS_FOR_SKALE_MANAGER

source venv/bin/activate
python -V
pip3 -V

case "$TEST_NAME" in

      "node_rotation")

            echo
            echo "----- integration_tests/skale-manager/ts_1/test.sh::node_rotation -----"

            PYTHONPATH=$INTEGRATION_TESTS_FOR_SKALE_MANAGER pytest --full-trace --showlocals -v -s $INTEGRATION_TESTS_FOR_SKALE_MANAGER/test/node_rotation_test.py::test_node_rotation

      ;;

      "get_schains_quantity")

            echo
            echo "----- scripts/schains.py get_schains_quantity_on_contract -----"

            PYTHONPATH=$INTEGRATION_TESTS_FOR_SKALE_MANAGER python scripts/schains.py get-schains-quantity-on-contract

      ;;

      # "schains_rotation")

      #       PYTHONPATH=$INTEGRATION_TESTS_FOR_SKALE_MANAGER pytest --full-trace --showlocals -v -s $INTEGRATION_TESTS_FOR_SKALE_MANAGER/test/schains_test.py::test_created_in_sequence

      # ;;

      "schains_delete_all")

            echo
            echo "----- integration_tests/skale-manager/ts_1/test.sh::schains_delete_all -----"

            PYTHONPATH=$INTEGRATION_TESTS_FOR_SKALE_MANAGER python scripts/schains.py remove-all

      ;;

      "schains_smoke_create_destroy")

            echo
            echo "----- integration_tests/skale-manager/ts_1/test.sh::schains_create_destroy -----"

            PYTHONPATH=$INTEGRATION_TESTS_FOR_SKALE_MANAGER pytest --full-trace --showlocals -v -s $INTEGRATION_TESTS_FOR_SKALE_MANAGER/test/schains_test.py::test_created_in_sequence

      ;;

      "schains_create_destroy")

            echo
            echo "----- integration_tests/skale-manager/ts_1/test.sh::schains_create_destroy -----"

            PYTHONPATH=$INTEGRATION_TESTS_FOR_SKALE_MANAGER pytest --full-trace --showlocals -v -s $INTEGRATION_TESTS_FOR_SKALE_MANAGER/test/schains_test.py::test_long_run_create_destroy

      ;;

      *)
            echo "Test [${TEST_NAME}] doesn't exist. Try another."
            false
      ;;
esac

result=$?

echo "----- integration_tests/skale-manager/ts_1/environment.sh ----- end"
echo

exit $result
