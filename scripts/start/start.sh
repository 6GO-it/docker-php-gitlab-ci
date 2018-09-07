#!/usr/bin/env bash

docker stop $1
docker rm -f $1
docker run \
	--name $1 \
	-d \
	-v "$(pdw):/root" \
	$2