
#!/bin/bash

echo
echo "----- integration_tests/skale-manager/ts_1/environment.sh ----- begin"

export SKALE_MANAGER_TS_1=$INTEGRATION_TESTS_DIR/skale-manager/ts_1
echo "SKALE_MANAGER_TS_1 = $SKALE_MANAGER_TS_1"
export INTEGRATION_TESTS_FOR_SKALE_MANAGER=$SKALE_MANAGER_TS_1/third_party/integration_tests_for_skale-manager
echo "INTEGRATION_TESTS_FOR_SKALE_MANAGER = $INTEGRATION_TESTS_FOR_SKALE_MANAGER"

cd $INTEGRATION_TESTS_FOR_SKALE_MANAGER

echo $INTEGRATION_TESTS_FOR_SKALE_MANAGER

rm -rf venv
python3 -m venv venv
. venv/bin/activate

python -V
pip -V

pip3 install wheel
pip3 install cython
pip3 install greenlet
pip3 install gevent
pip3 install setuptools
pip3 install parallel-ssh

pip3 install -r requirements.txt

echo "----- integration_tests/skale-manager/ts_1/environment.sh ----- end"
echo
