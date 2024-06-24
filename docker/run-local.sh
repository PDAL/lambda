#!/bin/bash

# ./run-local.sh /var/task/python-entry.sh pdal_lambda.ecr.info.handler

entrypoint="$1"
command="$2"


PREFIX=$(cat ../terraform/terraform.tfstate | jq '.outputs.environment.value // empty' -r)
STAGE=$(cat ../terraform/terraform.tfstate | jq '.outputs.stage.value // empty' -r)
ARCH=$(cat ../terraform/terraform.tfstate | jq '.outputs.arch.value // empty' -r)

if [ -z "$STAGE" ]
then
    echo "STAGE must be set!"
    exit 1;
fi

if [ -z "$PREFIX" ]
then
    echo "PREFIX must be set!"
    exit 1;
fi

if [ -z "$ARCH" ]
then
    echo "ARCH must be set!"
    exit 1;
fi

CONTAINER="$PREFIX-$STAGE-pdal_runner"

REGION=$AWS_DEFAULT_REGION
if [ -z "$REGION" ]
then
    echo "AWS_DEFAULT_REGION must be set!"
    exit 1;
fi

LOCALPORT=9000
REMOTEPORT=8080

identity=$(aws sts get-caller-identity --query 'Account' --output text)

KEY_ID=$(aws --profile $AWS_DEFAULT_PROFILE configure get aws_access_key_id)
SECRET_ID=$(aws --profile $AWS_DEFAULT_PROFILE configure get aws_secret_access_key)


echo "running $identity.dkr.ecr.$region.amazonaws.com/$container:$ARCH"

if [ -z "$entrypoint" ]
then
    echo "executing default entrypoint using $command"
    docker run -p $LOCALPORT:$REMOTEPORT \
        -e AWS_DEFAULT_REGION=$REGION \
        -e AWS_ACCESS_KEY_ID=${KEY_ID} \
        -e AWS_SECRET_ACCESS_KEY=${SECRET_ID} \
        $identity.dkr.ecr.$REGION.amazonaws.com/$CONTAINER:$ARCH "$command"
else
    echo "executing with $entrypoint and command '$command'"
    docker run -p $LOCALPORT:$REMOTEPORT \
        -e AWS_DEFAULT_REGION=$REGION \
        -e AWS_ACCESS_KEY_ID=$KEY_ID \
        -e AWS_SECRET_ACCESS_KEY=$SECRET_ID \
        -t -i \
        -v $(pwd):/data \
        --entrypoint=$entrypoint \
        $identity.dkr.ecr.$REGION.amazonaws.com/$CONTAINER:$ARCH \
        "$command"
fi

