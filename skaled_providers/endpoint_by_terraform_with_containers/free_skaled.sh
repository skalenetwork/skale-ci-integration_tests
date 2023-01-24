#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -- De-Terraform --
cd $SCRIPT_DIR/tf

PARALLEL_FUNC () {
    ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- 111
	sudo -i
	docker stop skale-ci-0
    umount /dev/xvdd
111
}

for i in $( seq 0 $(($NUM_NODES-1)) )
do
    IP=$( jq -r '.public_ips.value."skale-ci-'${i}'"' output.json )
    if [ "$IP" = "null" ]; then exit 1; fi
	IP=$IP PARALLEL_FUNC&
done

wait

./destroy.sh

cd ..
