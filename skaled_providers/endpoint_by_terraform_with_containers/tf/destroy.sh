#!/bin/bash

set -a
. ./.env
set +a

cd tf_scripts && export TF_VAR_prefix=${DROPLET_NAME} && export TF_VAR_COUNT=${NODES} && terraform destroy -var="path_to_pem=~/elvis-oregon.pem" -auto-approve
