#!/bin/bash

cd third_party/rpc_bomber 

I=0
for URL in $@
do
	node rpc_bomber.js -t --from $((I*1000)) $URL 2>&1 >bomber_${I}.log&
	I=$((I+1))
done

wait

cd ../..
