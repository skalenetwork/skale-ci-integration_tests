
#!/bin/bash

echo
echo "----- integration_tests/skaled/stability/environment.sh ----- begin"

export STABILITY=$INTEGRATION_TESTS_DIR/skaled/stability

rm -rf venv
python3 -m venv venv
. venv/bin/activate

python -V
pip -V

pip3 install wheel

pip3 install -r requirements.txt

echo "----- integration_tests/skaled/stability/environment.sh ----- end"
echo
