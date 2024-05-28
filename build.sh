#!/bin/sh

set -e
container="$1"
if [ -z "$container" ]
then
    echo "container name not set! please execute './build.sh containername'"
    exit 1;
fi
WIPE_CACHE="$2"
if [ -z "$WIPE_CACHE" ]; then
    echo "Not wiping cache";
else
    WIPE_CACHE="--no-cache"
    echo "Wiping cache '$WIPE_CACHE'";

fi

region=$AWS_DEFAULT_REGION
if [ -z "$region" ]
then
    echo "$AWS_DEFAULT_REGION must be set!"
    exit 1;
fi
identity=$(aws sts get-caller-identity --query 'Account' --output text)
if [ -z "$identity" ]
then
    echo "Unable to fetch identity from aws sts to name container!"
    exit 1;
fi

CONTAINER_NAME=$identity.dkr.ecr.$region.amazonaws.com/$container

LAMBDA_IMAGE="amazon/aws-lambda-provided:al2"
docker buildx build -t $CONTAINER_NAME:amd64 . \
    --build-arg LAMBDA_IMAGE="${LAMBDA_IMAGE}" \
    --build-arg RIE_ARCH=x86_64 \
    --platform linux/amd64  \
    -f Dockerfile --load

LAMBDA_IMAGE="amazon/aws-lambda-provided:al2023.2024.05.01.10"
docker buildx build -t $CONTAINER_NAME:arm64 . \
    -f Dockerfile --platform linux/arm64 \
    --build-arg LAMBDA_IMAGE=$LAMBDA_IMAGE \
    $WIPE_CACHE \
    --build-arg RIE_ARCH=arm64 --load
