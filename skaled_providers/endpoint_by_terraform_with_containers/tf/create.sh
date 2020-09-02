#!/bin/bash

set -a
. ./.env
set +a

cd tf_scripts && export TF_VAR_prefix=${DROPLET_NAME} && export TF_VAR_COUNT=${NUM_NODES} && terraform plan -var="path_to_pem=~/elvis-oregon.pem" -out=tfplan && terraform apply -input=false tfplan
terraform output -json > ../output.json
