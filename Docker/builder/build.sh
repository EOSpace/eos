#!/bin/bash

nohup docker build -t eospace/eos-builder -f Dockerfile.custom . > build.log &
