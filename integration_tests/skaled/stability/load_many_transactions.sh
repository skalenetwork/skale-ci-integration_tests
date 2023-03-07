#!/bin/bash

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
	npx hardhat setStorageUsage --size 1g --network custom
	sleep 10
done
}

#killer_func 2>&1 >blockchain-killer.log&

cd ../..

cd third_party/rpc_bomber 

I=1
for URL in ${@:2}
do
	node rpc_bomber.js -t --from $((I*1000)) -d 54000 -b 50 $URL 2>&1 >bomber_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
done

trap 'kill -INT ${PIDS[*]}' INT

wait

cd ../..
