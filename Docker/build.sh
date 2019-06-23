#!/bin/bash
TAG=v1.7.3
BRANCH=eospace/feature/kafka_plugin
nohup docker build -t eospace/eos:$TAG -f Dockerfile.custom --build-arg branch=$BRANCH --build-arg symbol=EOS . > build.log &
