#!/bin/sh

container="$1"
tag="$2"

if [ -z "$container" ]
then
    echo "container name not set! please execute ./build.sh containername'"
fi
region="$AWS_DEFAULT_REGION"
echo "region: $region"

# login to docker
eval $(aws ecr get-login --no-include-email --region $region)
identity=$(aws sts get-caller-identity --query 'Account' --output text)



CONTAINER_NAME=$identity.dkr.ecr.$region.amazonaws.com/$container:$tag
echo $CONTAINER_NAME
docker push "$CONTAINER_NAME"
