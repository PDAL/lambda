#!/bin/bash

#LAYERNAME="pdal"

create_layer()
{
    LAYERNAME="$1"
    ZIPFILE="$2"
    DESCRIPTION="$3"
    RUNTIMES="$4"

    LAYER=$(aws lambda publish-layer-version \
        --layer-name $LAYERNAME \
        --description "$DESCRIPTION" \
        --zip-file fileb://./$ZIPFILE\
        --compatible-runtimes "$RUNTIMES" \
        --license-info BSD \
        --region $AWS_REGION \
        --profile $AWS_PROFILE)


    VERSION=$(aws lambda list-layers --region $AWS_REGION |jq '.Layers[]| select(.LayerName=="'$LAYERNAME'").LatestMatchingVersion.Version' -r)

    echo "Published version $VERSION for Lambda layer $LAYERNAME"

    LAYER=$(aws lambda get-layer-version \
        --layer-name $LAYERNAME \
        --version-number $VERSION \
        --region $AWS_REGION \
        --profile $AWS_PROFILE)


    echo "Setting execution access to public for version $VERSION for Lambda layer $LAYERNAME"
    PERMISSION=$(aws lambda add-layer-version-permission \
        --layer-name $LAYERNAME \
        --version-number $VERSION \
        --statement-id "run-pdal-publicly" \
        --principal '*' \
        --action lambda:GetLayerVersion \
        --region $AWS_REGION \
        --profile $AWS_PROFILE )

    LAYERARN=$(echo $LAYER | jq -r .LayerArn)

    echo "Layer $LAYERNAME is available at '$LAYERARN'"

}

create_layer "pdal" "pdal-lambda-deploy.zip" "PDAL 2.2.0 software" "provided"
create_layer "pdal-python" "pdal-python-lambda-deploy.zip" "PDAL Python 2.3.5 software" "python3.7"
