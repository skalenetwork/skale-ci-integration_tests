#!/bin/bash -x

HOST=$1
CHAIN=$2

#SSH_ARGS="-i ~/.just_works/l_sergiy.pem ubuntu@ec2-18-191-133-247.us-east-2.compute.amazonaws.com"
SSH_ARGS=root@$HOST

CONTAINER=skale_schain_$CHAIN

SKALED_PATH=/root/skaled
#SKALED_PATH=/home/ubuntu/Work/Natasha/skale-node-tests-jenkins/skaled
ssh $SSH_ARGS docker cp $CONTAINER:/skaled/skaled $SKALED_PATH

SKALED_PID=$(ssh $SSH_ARGS pgrep -f skaled.\*$CHAIN)
ssh $SSH_ARGS apt -y install gdb
ssh $SSH_ARGS gcore -o /root/core $SKALED_PID

CORE_PATH=/root/core.$SKALED_PID
#CORE_PATH=/home/ubuntu/.jenkins/workspace/Ten\\\ Accounts\\\ Parallel\\\ Running/core
#CORE_PATH=/home/ubuntu/Work/Natasha/skale-node-tests/core

LIBS="/lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/librt.so.1 /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libc.so.6 /lib64//ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/libnss_files.so.2 /lib/x86_64-linux-gnu/libnss_dns.so.2 /lib/x86_64-linux-gnu/libresolv.so.2"

ssh $SSH_ARGS docker exec $CONTAINER tar cvzf /root/so.tar.gz -h $LIBS
ssh $SSH_ARGS docker cp $CONTAINER:/root/so.tar.gz /root/

scp $SSH_ARGS:$SKALED_PATH ./skaled.$SKALED_PID
scp $SSH_ARGS:"$CORE_PATH" .
scp $SSH_ARGS:/root/so.tar.gz .
