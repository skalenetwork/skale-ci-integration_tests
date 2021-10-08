#!/bin/bash

echo
echo "----- integration_tests/skaled/stability/test.sh ----- begin"

TEST_NAME=$1
KICK_INTERVAL=${KICK_INTERVAL:-30}

export STABILITY=$INTEGRATION_TESTS_DIR/skaled/stability

. $SKALED_PROVIDER/get_skaled.sh $STABILITY/accounts_plus_options.json

cd $STABILITY

source venv/bin/activate
python -V
pip3 -V

#TODO kill at signal!

for IP in ${IPS[*]}
do
    URLS+=("http://$IP:${PORTS[0]}")
done
python3 txn_stream.py ${URLS[*]}&

set +x

ARGS=()
ARGS+=("ban all 2")
ARGS+=("down 12 0")
ARGS+=("ban all 3")
ARGS+=("down 13 0")
ARGS+=("ban all 4")
ARGS+=("down 14 0")
ARGS+=("ban all 5")
ARGS+=("down 15 0")

ARGS+=("down 6 0")
ARGS+=("down 7 0")
ARGS+=("up 7 0")
ARGS+=("up 6 0")

ARGS+=("up 15 0")
ARGS+=("unban all 5")
ARGS+=("up 14 0")
ARGS+=("unban all 4")
ARGS+=("up 13 0")
ARGS+=("unban all 3")
ARGS+=("up 12 0")
ARGS+=("unban all 2")

IFS=$'\t'

for A in ${ARGS[*]}
do
    sleep $KICK_INTERVAL
    echo $A
    bash $SKALED_PROVIDER/kick.sh $A    
done

IFS=' '

sleep 21600
kill $(jobs -p)
result=0

. $SKALED_PROVIDER/free_skaled.sh

echo "----- integration_tests/skaled/stability/test.sh ----- end"
echo

exit $result
