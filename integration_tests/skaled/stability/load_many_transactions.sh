#!/bin/bash

cd third_party/blockchain-killer
echo ENDPOINT=$1 >.env
echo PRIVATE_KEY=0x72280f79fb45fa984fe2c5677141419cf3bf4fe239857a8f9ea7d302d75b2af0 >>.env

npx hardhat run scripts/deploy.ts --network custom

nohup watch 'npx hardhat setStorageUsage --size 1g --network custom'&

cd ../..

cd third_party/rpc_bomber 

I=1
for URL in ${@:2}
do
	node rpc_bomber.js -t --from $((I*1000)) $URL 2>&1 >bomber_${I}.log&
	I=$((I+1))
done

wait

cd ../..
