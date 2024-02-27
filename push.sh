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
identity=$(aws sts get-caller-identity --query 'Account' --output text)

COMMAND="aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $identity.dkr.ecr.$region.amazonaws.com"
#COMMAND="aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/d4n0a3t5"

echo "$COMMAND"
eval $COMMAND

repository=$(aws ecr describe-repositories --repository-names $container)
echo "repository: ${repository}"


for tag in amd64 arm64;
do
    echo $Item
    CONTAINER_NAME=${identity}.dkr.ecr.${region}.amazonaws.com/${container}:$tag
#    CONTAINER_NAME=public.ecr.aws/d4n0a3t5/$container:$tag
    echo $CONTAINER_NAME
    docker push "$CONTAINER_NAME"
done



#CONTAINER_NAME=public.ecr.aws/d4n0a3t5/$container:latest
#docker manifest create "$CONTAINER_NAME" \
#    --amend "public.ecr.aws/d4n0a3t5/${container}:arm64" \
#    --amend "public.ecr.aws/d4n0a3t5/${container}:amd64"
CONTAINER_NAME=${identity}.dkr.ecr.${region}.amazonaws.com/${container}:latest
docker manifest rm "$CONTAINER_NAME"
docker manifest create "$CONTAINER_NAME" \
    --amend "${identity}.dkr.ecr.${region}.amazonaws.com/${container}:arm64" \
    --amend "${identity}.dkr.ecr.${region}.amazonaws.com/${container}:amd64"


docker manifest inspect $CONTAINER_NAME

docker manifest push "$CONTAINER_NAME"
