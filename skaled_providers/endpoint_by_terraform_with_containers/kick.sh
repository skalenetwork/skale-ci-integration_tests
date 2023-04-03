#!/bin/bash

ORIG_CWD="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

NUM_NODES=${NUM_NODES:-$( jq -r '.public_ips.value|length' tf/output.json )}
NUM_SCHAINS=${NUM_SCHAINS:-5}

for i in $( seq 0 $(($NUM_NODES-1)) )
do
        IPS[$i]=$( jq -r '.public_ips.value."skale-ci-'${i}'"' tf/output.json )
        if [ "${IPS[$i]}" = "null" ]; then exit 1; fi
done

cmd_node_schain () {
  local CMD=$1
  local I=$2
  local J=$3

  if [ $I == "all" ]
  then
    for II in $(seq 0 $((NUM_NODES-1)) )
    do
      cmd_node_schain $CMD $II $J&
    done
    wait
    return
  fi

  if [ $J == "all" ]
  then
    for JJ in $(seq 0 $((NUM_SCHAINS-1)) )
    do
      cmd_node_schain $CMD $I $JJ&
    done
    wait
    return
  fi

  $CMD $I $J ${@:3}
}

cmd_node_node () {
  local CMD=$1
  local I=$2
  local J=$3

  if [ $I == "all" ]
  then
    for II in $(seq 0 $((NUM_NODES-1)) )
    do
      cmd_node_node $CMD $II $J&
    done
    wait
    return
  fi

  if [ $J == "all" ]
  then
    for JJ in $(seq 0 $((NUM_NODES-1)) )
    do
      cmd_node_node $CMD $I $JJ&
    done
    wait
    return
  fi

  $CMD $I $J
}

up_cmd () {
  local I=$1
  local J=$2
  IP=${IPS[$I]}
  ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    sudo docker start skale-ci-$J
****
}

down_cmd () {
  local I=$1
  local J=$2
  IP=${IPS[$I]}
  ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    sudo docker stop skale-ci-$J
****
}

kill_cmd () {
  local I=$1
  local J=$2
  IP=${IPS[$I]}
  ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    sudo kill -9 $(pgrep -f '/skaled/skaled')
****
}

ban_cmd () {
  local I=$1
  local J=$2
  IP=${IPS[$I]}
  if [[ ${#J} -le 2 ]]
  then
    BAN_IP=${IPS[$J]}
  else
    BAN_IP="$J"
  fi
  ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    sudo route add $BAN_IP gw 127.0.0.1
****
}

unban_cmd () {
  local I=$1
  local J=$2
  IP=${IPS[$I]}
  if [[ ${#J} -le 2 ]]
  then
    BAN_IP=${IPS[$J]}
  else
    BAN_IP="$J"
  fi
  ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****
    sudo route del $BAN_IP
****
}

up () {
  cmd_node_schain up_cmd $1 $2
}

down () {
  cmd_node_schain down_cmd $1 $2
}

ban () {
  cmd_node_node ban_cmd $1 $2
}

unban () {
  cmd_node_node unban_cmd $1 $2
}

kill () {
  cmd_node_schain kill_cmd $1 $2
}

${@:1}

cd "$ORIG_CWD"
