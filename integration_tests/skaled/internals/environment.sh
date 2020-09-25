
#!/bin/bash

echo
echo "----- integration_tests/skaled/internals/environment.sh ----- begin"

export INTERNALS=$INTEGRATION_TESTS_DIR/skaled/internals
export SKALE_NODE_TESTS=$INTERNALS/third_party/skale-node-tests
echo "SKALE_NODE_TESTS = $SKALE_NODE_TESTS"

cd $SKALE_NODE_TESTS

rm -rf venv
python3 -m venv venv
. venv/bin/activate

python -V
pip -V

pip3 install wheel docker

pip3 install -r requirements.txt

echo "----- integration_tests/skaled/internals/environment.sh ----- end"
echo
