#!/bin/sh

docker rm $(docker ps --filter 'status=exited' -a -q)
docker rmi $(docker images | egrep -i "<none>" | awk '{print $3}')

