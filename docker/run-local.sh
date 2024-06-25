#!/bin/bash

# ./run-local.sh /var/task/python-entry.sh pdal_lambda.ecr.info.handler

entrypoint="$1"
command="$2"

CONTAINER=$(cat ../terraform/terraform.tfstate | jq '.outputs.container.value // empty' -r)

REGION=$AWS_DEFAULT_REGION
if [ -z "$REGION" ]
then
    echo "AWS_DEFAULT_REGION must be set!"
    exit 1;
fi

LOCALPORT=9000
REMOTEPORT=8080

KEY_ID=$(aws --profile $AWS_DEFAULT_PROFILE configure get aws_access_key_id)
SECRET_ID=$(aws --profile $AWS_DEFAULT_PROFILE configure get aws_secret_access_key)


echo "Starting container $CONTAINER"

if [ -z "$entrypoint" ]
then
    echo "executing default entrypoint using $command"
    docker run -p $LOCALPORT:$REMOTEPORT \
        -e AWS_DEFAULT_REGION=$REGION \
        -e AWS_ACCESS_KEY_ID=${KEY_ID} \
        -e AWS_SECRET_ACCESS_KEY=${SECRET_ID} \
        $CONTAINER "$command"
else
    echo "executing with $entrypoint and command '$command'"
    docker run -p $LOCALPORT:$REMOTEPORT \
        -e AWS_DEFAULT_REGION=$REGION \
        -e AWS_ACCESS_KEY_ID=$KEY_ID \
        -e AWS_SECRET_ACCESS_KEY=$SECRET_ID \
        -t -i \
        -v $(pwd):/data \
        --entrypoint=$entrypoint \
        $CONTAINER "$command"
fi

