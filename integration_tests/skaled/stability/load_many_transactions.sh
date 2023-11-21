#!/bin/bash

KICK_INTERVAL=${KICK_INTERVAL:-30}

# 1 bomb 1 hr with data

cd third_party/rpc_bomber

I=0
#skip $1 and $2 - both are URLs
for URL in ${@:2}
do
	node rpc_bomber.js -t --from $((I*1000)) -d 54000 --time $((KICK_INTERVAL*2)) -a 50 $URL 2>&1 >bomber_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
done

trap 'kill ${PIDS[*]}' INT TERM EXIT

echo "Waiting for bombers to finish"
wait ${PIDS[@]}
echo "Bombers finished"
unset PIDS

cd ../..

# 2 send contract calls for 1 hr
echo "Sending contract calls"
I=0
#skip $1 and $2 - both are URLs
for URL in ${@:2}
do
	python3 load_with_calls.py $URL $((I*250)) 250 2>&1 >calls_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
	python3 load_with_calls.py $URL $((I*250)) 250 2>&1 >calls_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
	python3 load_with_calls.py $URL $((I*250)) 250 2>&1 >calls_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
	python3 load_with_calls.py $URL $((I*250)) 250 2>&1 >calls_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
done

# 2.1 in parallel - send requests
cd third_party/rpc_bomber
node rpc_bomber.js -r -b 1000 --time $((KICK_INTERVAL*2)) $2 2>&1 >bomber_r.log&
PIDS[$I]=$!
cd ../..

trap 'kill ${PIDS[*]}' INT TERM EXIT
sleep $((KICK_INTERVAL*2))
kill ${PIDS[*]}
unset PIDS

# 3 start killer forever

cd third_party/blockchain-killer

echo ENDPOINT=$1 >.env
echo PRIVATE_KEY=0x21ec9f01cee2a87f8071c4c6ca6a8b218607bd4faa8b1bdacc71ff8c0618b2dd >>.env

while ! npx hardhat run scripts/deploy.ts --network custom
do
true
done

killer_func () {
while true
do
	timeout 5m npx hardhat setStorageUsage --size 2g --network custom
	sleep 10
done
}

#killer_func 2>&1 >blockchain-killer.log&
#KILLER_PID=$!

cd ../..

# 4 bomb without data

cd third_party/rpc_bomber

I=1
for URL in ${@:2}
do
	node rpc_bomber.js -t --from $((I*1000)) $URL 2>&1 >>bomber_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
done

trap 'kill ${PIDS[*]}' INT TERM EXIT

echo "Waiting for bombers to finish 2"
wait ${PIDS[@]}
echo "Bombers finished 2"

wait $KILLER_PID

rm bomber*.log

cd ../..
