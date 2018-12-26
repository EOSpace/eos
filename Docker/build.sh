#!/bin/bash

docker build -t eospace/eos -f Dockerfile.custom $(dirname "${BASH_SOURCE[0]}")
