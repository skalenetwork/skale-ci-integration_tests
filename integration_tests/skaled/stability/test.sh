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

    #scp -o "StrictHostKeyChecking no" files_faucet.sh ubuntu@$IP:/home/ubuntu/
    #ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    #sudo ./files_faucet.sh ./data_dir/0/a5cf2af8/blocks_and_extras/* </dev/null 2>/dev/null >/dev/null &
#****

done
python3 txn_stream.py ${URLS[*]}&

set +x

if [ "$TEST_NAME" == "down_up" ]
then

ARGS=()
ARGS+=("ban all 2")
ARGS+=("down 12 0")
ARGS+=("ban all 3")
ARGS+=("down 13 0")
ARGS+=("ban all 4")
ARGS+=("down 14 0")
ARGS+=("ban all 5")
ARGS+=("down 15 0")

#ARGS+=("down 6 0")
#ARGS+=("down 7 0")
#ARGS+=("up 7 0")
#ARGS+=("up 6 0")

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

    sleep $KICK_INTERVAL

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
