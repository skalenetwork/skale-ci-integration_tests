#!/bin/bash

# destroy all skaled
docker stop $(docker ps -a -q)
true
