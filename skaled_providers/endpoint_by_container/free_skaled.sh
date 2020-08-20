#!/bin/bash

# destroy all skaled
docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q) || true
