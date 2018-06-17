#!/bin/bash

sudo docker build -t rnaseq-umi-cpp -f Dockerfile.build  ${PWD}
sudo docker run --rm -v ${PWD}:/local rnaseq-umi-cpp /bin/sh -c "cp -r source/w* /local/."
sudo docker build -t biodepot/rnaseq-umi-cpp:3.7-1.0  -f Dockerfile  ${PWD}
sudo docker build -t biodepot/alpine-multibwa:3.7-0.7.15  -f Dockerfile-multibwa  ${PWD}
sudo rm -rf w96 w384
