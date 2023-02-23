#!/bin/bash

# params:
# $1 - suffix

SUFFIX=$1

set -a
. ./.env
set +a

cd tf_scripts

if [ "$SUFFIX" != "" ]
then
  mv terraform.tfstate terraform.tfstate.backup
fi

mv terraform.tfstate$SUFFIX terraform.tfstate

export TF_VAR_prefix=${DROPLET_NAME} && export TF_VAR_COUNT=${NUM_NODES} && terraform destroy -var="path_to_pem=~/d4_aws.pem" -auto-approve

if [ "$SUFFIX" != "" ]
then
  mv terraform.tfstate.backup terraform.tfstate
fi
