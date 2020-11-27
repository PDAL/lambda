#!/bin/sh

CONTAINER="pdal-lambda"
docker build -t $CONTAINER -f Dockerfile .
rm -rf lambda
mkdir -p lambda

docker run -v `pwd`:/output $CONTAINER /package-pdal.sh
