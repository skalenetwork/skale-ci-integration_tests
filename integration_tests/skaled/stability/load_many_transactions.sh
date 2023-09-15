#!/bin/bash

cd third_party/blockchain-killer
echo ENDPOINT=$1 >.env
echo PRIVATE_KEY=0x21ec9f01cee2a87f8071c4c6ca6a8b218607bd4faa8b1bdacc71ff8c0618b2dd >>.env

while ! npx hardhat run scripts/deploy.ts --network custom
do
true
done

killer_func () {
sleep 3600
while true
do
	timeout 5m npx hardhat setStorageUsage --size 1g --network custom
	sleep 10
done
}

#killer_func 2>&1 >blockchain-killer.log&
#KILLER_PID=$!

cd ../..

# 2 send contract calls
echo "Sending contract calls"
I=0
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
trap 'kill ${PIDS[*]}' INT TERM EXIT
sleep 86400
kill ${PIDS[*]}
unset PIDS

cd third_party/rpc_bomber

# 1 bomb with data
I=1
for URL in ${@:2}
do
	node rpc_bomber.js -t --from $((I*1000)) -d 54000 --time 3600 -a 50 $URL 2>&1 >bomber_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
done

trap 'kill ${PIDS[*]}' INT TERM EXIT

echo "Waiting for bombers to finish"
wait ${PIDS[@]}
echo "Bombers finished"

# 3 bomb without data
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

cd ../..
