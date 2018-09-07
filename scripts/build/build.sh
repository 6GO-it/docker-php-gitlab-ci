#!/usr/bin/env bash

docker stop $1
docker rmi -f $1
docker build -t $1 .