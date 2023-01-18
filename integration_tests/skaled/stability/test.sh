#!/bin/bash

echo
echo "----- integration_tests/skaled/stability/test.sh ----- begin"

TEST_NAME=$1
KICK_INTERVAL=${KICK_INTERVAL:-30}
SGX_IP="34.223.63.227"
SGX_URL="https://${SGX_IP}:1026"

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

    #scp -o "StrictHostKeyChecking no" files_faucet.sh ubuntu@$IP:/home/ubuntu/
    #ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    #sudo ./files_faucet.sh ./data_dir/0/a5cf2af8/blocks_and_extras/* </dev/null 2>/dev/null >/dev/null &
#****

done
#python3 txn_stream.py 0 ${URLS[*]}&
cd third_party/rpc_bomber
node rpc_bomber.js -t ${URLS[0]}&
cd ../..

set +x

if [ "$TEST_NAME" == "down_up" ]
then

ARGS=()
ARGS+=("down 15 0")
ARGS+=("down 14 0")
ARGS+=("ban all 2")
ARGS+=("ban all 3")
ARGS+=("ban 4 $SGX_IP")
ARGS+=("ban 5 $SGX_IP")

ARGS+=("unban 5 $SGX_IP")
ARGS+=("unban 4 $SGX_IP")
ARGS+=("unban all 3")
ARGS+=("unban all 2")
ARGS+=("up 14 0")
ARGS+=("up 15 0")

IFS=$'\t'

I=1
for A in ${ARGS[*]}
do
    sleep $KICK_INTERVAL
    echo $A
    bash $SKALED_PROVIDER/kick.sh $A
    I=$((I+1))
done

IFS=' '

elif [ "$TEST_NAME" == "8x8" ]
then

while [ true ]
do
    sleep $KICK_INTERVAL

    for I in 0 1 2 3 4 5 6 7
    do
        for J in 8 9 10 11 12 13 14 15
        do
            echo ban $I $J
            bash $SKALED_PROVIDER/kick.sh ban $I $J
            bash $SKALED_PROVIDER/kick.sh ban $J $I
        done
    done

    #sleep $KICK_INTERVAL
    for I in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    do
        echo Down $I
        bash $SKALED_PROVIDER/kick.sh down $J 0
    done
    for I in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    do
        echo Up $I
        bash $SKALED_PROVIDER/kick.sh up $J 0
    done

    bash $SKALED_PROVIDER/kick.sh unban all all

done

fi

sleep 21600
kill $(jobs -p)
result=0

. $SKALED_PROVIDER/free_skaled.sh

echo "----- integration_tests/skaled/stability/test.sh ----- end"
echo

exit $result
