#!/bin/bash

HOST=$1
CHAIN=$2

#SSH_ARGS="-i ~/.just_works/l_sergiy.pem ubuntu@ec2-18-191-133-247.us-east-2.compute.amazonaws.com"
SSH_ARGS=root@$HOST

#DATA_DIR=/home/ubuntu/Work/Natasha/skale-node-tests-jenkins/skaled_logs/sktest_performance2nodes/1
#DATA_DIR=/home/ubuntu/.jenkins/workspace/Ten\\\ Accounts\\\ Parallel\\\ Running
DATA_DIR=/var/lib/rancher/convoy/devicemapper/mounts/$CHAIN

#scp $SSH_ARGS:"$DATA_DIR/aleth.err" .
#scp $SSH_ARGS:"$DATA_DIR/aleth.out" .
scp $SSH_ARGS:"$DATA_DIR/*.log" .
#scp $SSH_ARGS:"$DATA_DIR/ten_accounts.log" .
