#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# destroy all skaled
docker stop $(docker ps -a -q)
docker logs $(docker ps -a -q|head -n 1) 2>&1 > $SCRIPT_DIR/data_dir/aleth.out
true
