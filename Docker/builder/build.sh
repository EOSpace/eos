#!/bin/bash

docker build -t eospace/eos-builder -f Dockerfile.custom $(dirname "${BASH_SOURCE[0]}")
