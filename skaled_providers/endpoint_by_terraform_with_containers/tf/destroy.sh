#!/bin/bash

set -a
. ./.env
set +a

cd tf_scripts && export TF_VAR_prefix=${DROPLET_NAME} && export TF_VAR_COUNT=${NUM_NODES} && terraform destroy -var="path_to_pem=~/d4_aws.pem" -auto-approve
