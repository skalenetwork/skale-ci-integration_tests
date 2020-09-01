#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -- De-Terraform --
cd $SCRIPT_DIR/tf
./destroy.sh
cd ..
