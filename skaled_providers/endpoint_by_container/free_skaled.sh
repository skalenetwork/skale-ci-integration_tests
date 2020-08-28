#!/bin/bash

# destroy all skaled
docker_containers="$(docker ps -a -q)"
if [[ ! -z ${docker_containers} ]]; then
    echo "Docker containers to be deleted --->"
    docker stop ${docker_containers} && docker rm ${docker_containers}
    echo "<--- Docker containers to be deleted"
fi