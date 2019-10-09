# PHP Gitlab CI

Image specifically crafted to be used by Gitlab CI and any PHP project

## Before start

This docker image contains the basic for testing any PHP project inside Gitlab CI

## How to use this container

Using this docker is pretty simple:

- Clone the repository
- Change directory into this repository
- Build the image manually using the cli command `docker build -t name-of-the-image .`. We suggest using names that are related to Laravel just to have a clear sight of the role of the container
- Once you have the image you can start as many container as you want
- To start a container you can use `docker run -d -v $(pwd):/root --name some-name name-of-the-image`

There are some basics scripts that help you build and run the container:

- Build using scripts `./scripts/build/build.sh name-of-the-image`
- Start container using scripts `./scripts/start/start.sh name-of-the-container name-of-the-images`

## Options and configurations

No options are needed here.

## What is inside

You will find:

- Debian 8 as base OS
- Latest Nodejs and NPM
- Yarn as an alternative for NPM
- PHP 7.3+ with necessary extensions and xDebug installed
- Composer available globally
