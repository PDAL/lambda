#!/bin/bash

eventfilename=$1

FUNCTION_NAME=$(cat ../terraform/terraform.tfstate | jq '.outputs.info_lambda_name.value // empty' -r)


aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --invocation-type RequestResponse \
    --payload fileb://$eventfilename \
   response.json



