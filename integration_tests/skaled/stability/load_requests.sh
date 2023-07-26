#!/bin/bash

# inputs:
# $@ - urls to bomb

cd third_party/rpc_bomber

I=1
for URL in ${@:1}
do
    echo "Starting request bomber at" $URL
	node rpc_bomber.js -r -b 10 $URL 2>&1 >requests_${I}.log&
	PIDS[$I]=$!
	I=$((I+1))
done

trap 'kill -INT ${PIDS[*]}' INT EXIT

echo "Waiting for request bombers to finish"
wait ${PIDS[@]}
echo "Request bombers finished"
