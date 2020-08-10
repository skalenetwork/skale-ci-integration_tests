
#!/bin/bash

echo
echo "----- integration_tests/skaled/load_python/environment.sh ----- begin"

export LOAD_PYTHON=$INTEGRATION_TESTS_DIR/skaled/load_python
export SKALE_NODE_TESTS=$LOAD_PYTHON/third_party/skale-node-tests
echo "SKALE_NODE_TESTS = $SKALE_NODE_TESTS"

cd $SKALE_NODE_TESTS

rm -rf venv
python3 -m venv venv
. venv/bin/activate

python -V
pip -V

pip3 install wheel

pip3 install -r requirements.txt

echo "----- integration_tests/skaled/load_python/environment.sh ----- end"
echo
