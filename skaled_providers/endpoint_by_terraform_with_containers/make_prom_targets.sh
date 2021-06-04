#!/bin/bash

NUM_NODES=${NUM_NODES:-$( jq -r '.public_ips.value|length' tf/output.json )}
NUM_SCHAINS=${NUM_SCHAINS:-5}

for i in $( seq 0 $(($NUM_NODES-1)) )
do
        IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
        if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
done

echo -n '    - targets: ['
for IP in ${IPS[*]}
do
  echo -n "'$IP:9144',"
  echo -n "'$IP:9256'"
  if [ "$IP" != "${IPS[-1]}" ]
  then
    echo -n ','
  fi
done
echo ']'
