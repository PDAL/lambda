#!/bin/bash

container="$1"
tag="$2"
entrypoint="$3"
region=$AWS_DEFAULT_REGION

identity=$(aws sts get-caller-identity --query 'Account' --output text)
echo "entrypoint: $entrypoint"

if [ -z "$tag" ]
then
    tag="amd64"
fi

if [ -z "$entrypoint" ]
then
    docker run -p 9000:8080 $identity.dkr.ecr.$region.amazonaws.com/$container:$tag
else
    docker run -p 9000:8080 -t -i -v `pwd`:/data --entrypoint=$entrypoint $identity.dkr.ecr.$region.amazonaws.com/$container:$tag
fi

