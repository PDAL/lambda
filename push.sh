#!/bin/sh

container="$1"

if [ -z "$container" ]
then
    echo "container name not set! please execute ./build.sh containername'"
    exit
fi
region="$AWS_DEFAULT_REGION"
echo "region: ${region}"

# login to docker
eval $(aws ecr get-login --no-include-email --region ${region})
identity=$(aws sts get-caller-identity --query 'Account' --output text)

repository=$(aws ecr describe-repositories --repository-names $container)
echo "repository: ${repository}"


for tag in amd64 arm64;
do
    echo $Item
    CONTAINER_NAME=${identity}.dkr.ecr.${region}.amazonaws.com/${container}:$tag
    echo $CONTAINER_NAME
    docker push "$CONTAINER_NAME"
done



CONTAINER_NAME=${identity}.dkr.ecr.${region}.amazonaws.com/${container}:latest
docker manifest create "$CONTAINER_NAME" \
--amend "${identity}.dkr.ecr.${region}.amazonaws.com/${container}:arm64" \
--amend "${identity}.dkr.ecr.${region}.amazonaws.com/${container}:x86_64"

docker manifest inspect $CONTAINER_NAME

docker manifest push "$CONTAINER_NAME"