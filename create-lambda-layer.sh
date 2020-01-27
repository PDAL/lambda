
LAYERNAME="pdal"
LAYER=$(aws lambda publish-layer-version \
    --layer-name $LAYERNAME \
    --description "PDAL 2.0.1 softare" \
    --zip-file fileb://./lambda-deploy.zip \
    --compatible-runtimes "provided" \
    --license-info BSD \
    --region $AWS_REGION \
    --profile $AWS_PROFILE)


VERSION=$(aws lambda list-layers --region $AWS_REGION |jq '.Layers[]| select(.LayerName=="'$LAYERNAME'").LatestMatchingVersion.Version' -r)

echo "Published version $VERSION for Lambda layer $LAYERNAME"

LAYER=$(aws lambda get-layer-version \
    --layer-name pdal \
    --version-number $VERSION \
    --region $AWS_REGION \
    --profile $AWS_PROFILE)


echo "Setting execution access to public for version $VERSION for Lambda layer $LAYERNAME"
PERMISSION=$(aws lambda add-layer-version-permission \
    --layer-name pdal \
    --version-number $VERSION \
    --statement-id "run-pdal-publicly" \
    --principal '*' \
    --action lambda:GetLayerVersion \
    --region $AWS_REGION \
    --profile $AWS_PROFILE )

LAYERARN=$(echo $LAYER | jq -r .LayerArn)

echo "Layer $LAYERNAME is available at '$LAYERARN'"

