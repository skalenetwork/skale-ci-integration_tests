#!/bin/bash

# params:
# $1 - suffix

# results:
# output$SUFFIX.json

SUFFIX=$1

set -a
. ./.env
set +a

cd tf_scripts

if [ "$SUFFIX" != "" ]
then
  mv terraform.tfstate terraform.tfstate.backup
fi

export TF_VAR_prefix=${DROPLET_NAME} && export TF_VAR_COUNT=$((NUM_NODES/2)) && terraform plan -var="path_to_pem=~/d4_aws.pem" -out=tfplan && terraform apply -input=false tfplan

terraform output -json > ../output$SUFFIX.json
mv terraform.tfstate terraform.tfstate$SUFFIX 

if [ "$SUFFIX" != "" ]
then
  mv terraform.tfstate.backup terraform.tfstate
fi